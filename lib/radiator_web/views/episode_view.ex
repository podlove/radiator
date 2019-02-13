defmodule RadiatorWeb.EpisodeView do
  use RadiatorWeb, :view
  alias RadiatorWeb.EpisodeView

  alias HAL.{Document, Link, Embed}

  def render("index.json", assigns = %{episodes: episodes}) do
    render_many(episodes, EpisodeView, "episode.json", assigns)
  end

  def render("show.json", assigns = %{episode: episode}) do
    render_one(episode, EpisodeView, "episode.json", assigns)
  end

  def render("episode.json", %{conn: conn, episode: episode}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.podcast_episode_path(conn, :show, episode.podcast_id, episode)
    })
    |> Document.add_properties(%{
      id: episode.id,
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
      published_at: episode.published_at
    })
  end
end
