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

  # Channel fields that keep their name on the podcast.
  @channel_fields ~w(title subtitle summary description funding_url funding_text license
                     license_url link language author owner_name owner_email image_url
                     copyright explicit)a

  @doc "Translates a parsed feed."
  def translate(%Feed{channel: channel, items: items}) do
    identified = identify_items(items)

    %Translation{
      podcast: translate_channel(channel),
      episodes: Enum.map(identified, fn {guid, item} -> translate_item(item, guid) end),
      persons: collect_persons(channel, items),
      contributions: collect_contributions(identified),
      skipped: length(items) - length(identified)
    }
  end

  # --- channel --------------------------------------------------------------

  defp translate_channel(channel) do
    channel
    |> Map.take(@channel_fields)
    |> Map.merge(%{
      podcast_type: enum_value(PodcastType, channel.podcast_type),
      feed_guid: channel.guid,
      categories: Enum.map(channel.categories, &Map.from_struct/1)
    })
  end

  # --- items ----------------------------------------------------------------

  # Pairs each item with its identity and drops the ones that have none. Two
  # items with the same identity in one `ON CONFLICT DO UPDATE` is a
  # cardinality violation in Postgres; `uniq_by` keeps the first occurrence,
  # and feeds are ordered newest first.
  defp identify_items(items) do
    items
    |> Enum.map(&{identity(&1), &1})
    |> Enum.reject(&match?({nil, _item}, &1))
    |> Enum.uniq_by(&elem(&1, 0))
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
      chapters: Enum.map(item.chapters, &Map.from_struct/1),
      transcripts: Enum.map(item.transcripts, &Map.from_struct/1)
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

  # --- persons --------------------------------------------------------------

  # Channel-level persons get no contribution but often carry an image the
  # item-level entries lack.
  defp collect_persons(channel, items) do
    (channel.persons ++ Enum.flat_map(items, & &1.persons))
    |> Enum.reduce(%{}, fn person, acc ->
      key = Person.normalize(person.name)

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

  # Built from the identified items only, so a dropped item leaves no dangling
  # link behind.
  defp collect_contributions(identified) do
    identified
    |> Enum.flat_map(fn {guid, item} ->
      Enum.map(
        item.persons,
        &%{guid: guid, normalized_name: Person.normalize(&1.name), role: &1.role}
      )
    end)
    |> Enum.uniq_by(&{&1.guid, &1.normalized_name})
  end

  # --- helpers --------------------------------------------------------------

  defp enum_value(type, value) do
    case Ash.Type.cast_input(type, value) do
      {:ok, casted} -> casted
      _other -> nil
    end
  end

  defp first_present(values), do: Enum.find(values, &present?/1)

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
end
