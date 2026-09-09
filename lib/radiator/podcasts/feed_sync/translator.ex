defmodule Radiator.Podcasts.FeedSync.Translator do
  @moduledoc """
  Translates a parsed feed into Radiator attributes.

  This is the anti-corruption layer. `Radiator.Feeds` speaks RSS — `item`,
  `enclosure`, `itunes:episode`. `Radiator.Podcasts` speaks Radiator —
  `Episode`, `number`, `Chapter`. Everything that maps one onto the other lives
  here and nowhere else, so neither side has to know the other's words.

  Pure: no database, no network, no Ash.
  """

  alias Radiator.Feeds.Feed
  alias Radiator.Podcasts.EpisodeType
  alias Radiator.Podcasts.FeedSync.Translation
  alias Radiator.Podcasts.Person
  alias Radiator.Podcasts.PodcastType

  @doc "Translates a parsed feed."
  def translate(%Feed{channel: channel, items: items}) do
    {episodes, skipped} = translate_items(items)

    %Translation{
      podcast: translate_channel(channel),
      episodes: episodes,
      persons: collect_persons(channel, items),
      contributions: collect_contributions(episodes, items),
      skipped: skipped
    }
  end

  # --- channel --------------------------------------------------------------

  defp translate_channel(channel) do
    %{
      title: channel.title,
      subtitle: channel.subtitle,
      summary: channel.summary,
      description: channel.description,
      funding_url: channel.funding_url,
      funding_text: channel.funding_text,
      license: channel.license,
      license_url: channel.license_url,
      link: channel.link,
      language: channel.language,
      author: channel.author,
      owner_name: channel.owner_name,
      owner_email: channel.owner_email,
      image_url: channel.image_url,
      copyright: channel.copyright,
      podcast_type: enum_value(PodcastType, channel.podcast_type),
      explicit: channel.explicit,
      feed_guid: channel.guid,
      categories: Enum.map(channel.categories, &%{text: &1.text, subcategory: &1.subcategory})
    }
  end

  # --- items ----------------------------------------------------------------

  # Two items with the same identity in one `ON CONFLICT DO UPDATE` is a
  # cardinality violation in Postgres. The first occurrence wins; feeds are
  # ordered newest first.
  defp translate_items(items) do
    items
    |> Enum.reduce({[], MapSet.new(), 0}, fn item, {acc, seen, skipped} ->
      guid = identity(item)

      cond do
        is_nil(guid) -> {acc, seen, skipped + 1}
        MapSet.member?(seen, guid) -> {acc, seen, skipped + 1}
        true -> {[translate_item(item, guid) | acc], MapSet.put(seen, guid), skipped}
      end
    end)
    |> then(fn {acc, _seen, skipped} -> {Enum.reverse(acc), skipped} end)
  end

  # Without any of these the item would be inserted afresh on every sync.
  defp identity(item) do
    cond do
      present?(item.guid) -> item.guid
      present?(item.link) -> item.link
      item.enclosure && present?(item.enclosure.url) -> item.enclosure.url
      true -> nil
    end
  end

  defp translate_item(item, guid) do
    %{
      guid: guid,
      title: title(item, guid),
      number: item.number,
      season: item.season,
      episode_type: enum_value(EpisodeType, item.episode_type),
      subtitle: item.subtitle,
      summary: first_present([item.itunes_summary, item.description]),
      content_html: item.content_html,
      author: item.author,
      chapters_url: item.chapters_url,
      chapters_type: item.chapters_type,
      link: item.link,
      published_at: item.published_at,
      duration_seconds: item.duration_seconds,
      image_url: item.image_url,
      enclosure_url: item.enclosure && item.enclosure.url,
      enclosure_length: item.enclosure && item.enclosure.length,
      enclosure_type: item.enclosure && item.enclosure.type,
      chapters: Enum.map(item.chapters, &chapter/1),
      transcripts: Enum.map(item.transcripts, &transcript/1)
    }
  end

  # `Episode.title` is required, `<title>` is optional in RSS. The last link
  # always holds because items without identity are already gone.
  defp title(item, guid) do
    cond do
      present?(item.title) -> item.title
      present?(item.itunes_title) -> item.itunes_title
      item.number -> "Episode #{item.number}"
      true -> guid
    end
  end

  defp chapter(chapter) do
    %{
      start_ms: chapter.start_ms,
      title: chapter.title,
      href: chapter.href,
      image_url: chapter.image_url
    }
  end

  defp transcript(transcript) do
    %{
      url: transcript.url,
      type: transcript.type,
      language: transcript.language,
      rel: transcript.rel
    }
  end

  # --- persons --------------------------------------------------------------

  # Channel-level persons get no contribution but often carry an image the
  # item-level entries lack.
  defp collect_persons(channel, items) do
    (channel.persons ++ Enum.flat_map(items, & &1.persons))
    |> Enum.reduce(%{}, fn person, acc ->
      key = normalize(person.name)

      Map.update(acc, key, new_person(person, key), &fill(&1, person))
    end)
    |> Map.values()
  end

  defp new_person(person, key) do
    %{
      name: person.name,
      normalized_name: key,
      uri: person.uri,
      image_url: person.image_url
    }
  end

  defp fill(existing, person) do
    %{
      existing
      | uri: existing.uri || person.uri,
        image_url: existing.image_url || person.image_url
    }
  end

  # Built against the translated episodes, so a dropped item leaves no
  # dangling link behind.
  defp collect_contributions(episodes, items) do
    guids = MapSet.new(episodes, & &1.guid)

    items
    |> Enum.flat_map(fn item ->
      case identity(item) do
        nil -> []
        guid -> Enum.map(item.persons, &contribution(guid, &1))
      end
    end)
    |> Enum.filter(&MapSet.member?(guids, &1.guid))
    |> Enum.uniq_by(&{&1.guid, &1.normalized_name})
  end

  defp contribution(guid, person) do
    %{guid: guid, normalized_name: normalize(person.name), role: person.role}
  end

  # --- helpers --------------------------------------------------------------

  defp enum_value(_type, nil), do: nil

  defp enum_value(type, value) do
    case Ash.Type.cast_input(type, value) do
      {:ok, casted} -> casted
      _other -> nil
    end
  end

  defp normalize(name), do: Person.normalize(name)

  defp first_present(values), do: Enum.find(values, &present?/1)

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
end
