defmodule Radiator.Feed.EpisodeBuilder do
  import XmlBuilder
  import Radiator.Feed.Builder, only: [add: 2]
  import Radiator.Feed.Guards
  import Radiator.Feed.Common

  require Logger

  alias Radiator.Directory.{Episode, Audio}
  alias Radiator.Contribution.Person
  alias Radiator.Contribution.AudioContribution
  alias Radiator.Storage.FileSlot

  import RadiatorWeb.FormatHelpers, only: [format_normal_playtime_round_to_seconds: 1]

  def new(feed_data, episode) do
    element(:item, fields(feed_data, episode))
  end

  def fields(%{type: type}, episode) do
    []
    |> add(guid(episode))
    |> add(element(:title, episode.title))
    |> add(element(:link, Episode.public_url(episode)))
    |> add(subtitle(episode))
    |> add(description(episode))
    |> add(summary(episode))
    |> add(publication_date(episode))
    |> add(duration(episode.audio))
    |> add(enclosure(episode, type))
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

  defp enclosure(episode = %Episode{audio: %Audio{files: files}}, type) do
    files
    |> Enum.find(fn file -> file.slot == type end)
    |> case do
      slot = %FileSlot{} ->
        element(:enclosure, %{
          url: Episode.enclosure_tracking_url(episode, type) |> IO.inspect(),
          type: slot.file.mime_type,
          length: slot.file.size
        })

      _ ->
        Logger.warn(
          "[Feed Builder] Episode \"#{episode.title}\" (##{episode.id}) has no #{type} enclosure"
        )

        nil
    end
  end

  defp enclosure(%Episode{id: id, title: title}, _) do
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
