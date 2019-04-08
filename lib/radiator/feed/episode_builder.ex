defmodule Radiator.Feed.EpisodeBuilder do
  import XmlBuilder
  import Radiator.Feed.Builder, only: [add: 2]
  import Radiator.Feed.Guards

  alias Radiator.Directory.Episode

  def new(feed_data, episode) do
    element(:item, fields(feed_data, episode))
  end

  def fields(_, episode) do
    []
    |> add(element(:title, episode.title))
    |> add(subtitle(episode))
    |> add(description(episode))
    |> add(enclosure(episode))
    |> add(guid(episode))
    |> add(chapters(episode))
    |> Enum.reverse()
  end

  defp subtitle(%Episode{subtitle: subtitle}) when set?(subtitle),
    do: element("itunes:subtitle", subtitle)

  defp subtitle(_), do: nil

  defp description(%Episode{description: description}) when set?(description),
    do: element(:description, description)

  defp description(_), do: nil

  # thought: it might be useful to build in validation while buildung.
  # For example, either I return {:ok, element} or {:error, reason}.
  # :ok tuples are added to the tree, errors and warnings are collected.
  # For example, a missing enclosure URL is an error, but a subtitle that
  # is too short is a notice or warning.
  # However, maybe it's better if the builder focuses on building and
  # a totally different module takes care of validation / hints.
  # Well, the builder could focus only on hard RSS requirements,
  # so either :ok or :error.
  defp enclosure(episode) do
    element(:enclosure, %{
      url: episode.enclosure_url,
      type: episode.enclosure_type,
      length: episode.enclosure_length
    })
  end

  defp guid(%Episode{guid: guid}) do
    element(:guid, %{isPermaLink: "false"}, guid)
  end

  defp chapters(%Episode{chapters: chapters}) when length(chapters) > 0 do
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
          |> maybe_put(:image, Map.get(chapter, :image))
        )
      end)
    )
  end

  defp chapters(_), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
