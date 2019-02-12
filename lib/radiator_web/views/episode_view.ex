defmodule RadiatorWeb.EpisodeView do
  use RadiatorWeb, :view
  alias RadiatorWeb.EpisodeView

  def render("index.json", %{episodes: episodes}) do
    %{data: render_many(episodes, EpisodeView, "episode.json")}
  end

  def render("show.json", %{episode: episode}) do
    %{data: render_one(episode, EpisodeView, "episode.json")}
  end

  def render("episode.json", %{episode: episode}) do
    %{id: episode.id,
      title: episode.title,
      subtitle: episode.subtitle,
      description: episode.description,
      content: episode.content,
      image: episode.image,
      enclosure_url: episode.enclosure_url,
      enclosure_length: episode.enclosure_length,
      enclosure_type: episode.enclosure_type,
      duration: episode.duration,
      guid: episode.guid,
      number: episode.number,
      published_at: episode.published_at}
  end
end
