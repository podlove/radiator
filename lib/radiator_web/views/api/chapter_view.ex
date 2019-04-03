defmodule RadiatorWeb.Api.ChapterView do
  use RadiatorWeb, :view

  def render("chapter.json", %{chapter: chapter}) do
    %{
      start: Map.get(chapter, :time) |> Chapters.Formatters.Normalplaytime.Formatter.format(),
      title: Map.get(chapter, :title)
    }
    |> maybe_put(:href, Map.get(chapter, :url))
    |> maybe_put(:image, Map.get(chapter, :image))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
