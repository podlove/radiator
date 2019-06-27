defmodule RadiatorWeb.Public.EpisodeView do
  use RadiatorWeb, :view

  import RadiatorWeb.ContentHelpers

  def page_title(_template, %{current_podcast: podcast, current_episode: episode}) do
    [podcast.title, episode.title]
    |> Enum.join(" – ")
  end

  def page_title(_template, %{current_podcast: podcast}) do
    podcast.title
  end

  def format_date(datetime) do
    Timex.Format.DateTime.Formatters.Relative.format(datetime, "{relative}")
    |> case do
      {:ok, result} -> result
    end
  end
end
