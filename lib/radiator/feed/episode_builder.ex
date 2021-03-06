defmodule Radiator.Feed.EpisodeBuilder do
  import XmlBuilder
  import Radiator.Feed.Builder, only: [add: 2]
  import Radiator.Feed.Guards
  import Radiator.Feed.Common

  require Logger

  alias Radiator.Directory.{Episode, Audio}
  alias Radiator.Contribution.Person
  alias Radiator.Contribution.AudioContribution
  import RadiatorWeb.FormatHelpers, only: [format_normal_playtime_round_to_seconds: 1]

  def new(feed_data, episode) do
    element(:item, fields(feed_data, episode))
  end

  def fields(_, episode) do
    []
    |> add(guid(episode))
    |> add(element(:title, episode.title))
    |> add(element(:link, Episode.public_url(episode)))
    |> add(subtitle(episode))
    |> add(description(episode))
    |> add(summary(episode))
    |> add(publication_date(episode))
    |> add(duration(episode.audio))
    |> add(enclosure(episode))
    |> add(contributors(episode))
    |> add(chapters(episode))
    |> add(content(episode))
    |> Enum.reverse()
  end

  # Both subtitle and description are derived from the subtitle property intentionally
  defp subtitle(%Episode{subtitle: subtitle}) when set?(subtitle),
    do: element("itunes:subtitle", subtitle)

  defp subtitle(_), do: nil

  defp description(%Episode{subtitle: description}) when set?(description),
    do: element(:description, description)

  defp description(_), do: nil

  defp summary(%Episode{summary: summary}) when set?(summary),
    do: element("itunes:summary", summary)

  defp summary(_), do: nil

  defp content(%Episode{summary_html: summary_html}) when set?(summary_html),
    do: element("content:encoded", {:cdata, summary_html})

  defp content(_), do: nil

  # thought: it might be useful to build in validation while building.
  # For example, either I return {:ok, element} or {:error, reason}.
  # :ok tuples are added to the tree, errors and warnings are collected.
  # For example, a missing enclosure URL is an error, but a subtitle that
  # is too short is a notice or warning.
  # However, maybe it's better if the builder focuses on building and
  # a totally different module takes care of validation / hints.
  # Well, the builder could focus only on hard RSS requirements,
  # so either :ok or :error.
  defp enclosure(%Episode{audio: %Audio{audio_files: [enclosure]}} = episode) do
    element(:enclosure, %{
      url: Episode.enclosure_url(episode),
      type: enclosure.mime_type,
      length: enclosure.byte_length
    })
  end

  defp enclosure(%Episode{id: id, title: title}) do
    Logger.warn("[Feed Builder] Episode \"#{title}\" (##{id}) has no enclosure")
    nil
  end

  defp duration(%Audio{duration: time}) when not is_nil(time) do
    element("itunes:duration", format_normal_playtime_round_to_seconds(time))
  end

  defp duration(_), do: nil

  defp contributors(%Episode{audio: %Audio{contributions: contributions}}) do
    if Ecto.assoc_loaded?(contributions) do
      contributions
      |> Enum.filter(fn %AudioContribution{person: %Person{display_name: name}} ->
        String.valid?(name) && String.length(name) > 0
      end)
      |> Enum.map(&contributor/1)
    else
      []
    end
  end

  defp contributors(_), do: nil

  defp guid(%Episode{guid: guid}) do
    element(:guid, %{isPermaLink: "false"}, guid)
  end

  defp chapters(%Episode{audio: %Audio{chapters: chapters}}) when length(chapters) > 0 do
    element(
      :"psc:chapters",
      %{"version" => 1.2},
      Enum.map(chapters, fn chapter ->
        element(
          :"psc:chapter",
          %{
            start:
              Map.get(chapter, :start) |> Chapters.Formatters.Normalplaytime.Formatter.format(),
            title: Map.get(chapter, :title)
          }
          |> maybe_put(:href, Map.get(chapter, :link))
          |> maybe_put(:image, Radiator.AudioMeta.Chapter.image_url(chapter))
        )
      end)
    )
  end

  defp chapters(_), do: nil

  defp publication_date(%Episode{published_at: published_at}),
    do: element(:pubDate, Timex.format!(published_at, "{RFC822}"))

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
