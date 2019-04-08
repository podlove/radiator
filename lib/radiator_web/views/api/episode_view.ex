defmodule RadiatorWeb.Api.EpisodeView do
  use RadiatorWeb, :view
  alias RadiatorWeb.Api.{ChapterView, EpisodeView, PodcastView}

  alias HAL.{Document, Link, Embed}
  alias Radiator.Directory.Podcast

  def render("index.json", assigns = %{podcast: podcast, episodes: episodes}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_podcast_episode_path(assigns.conn, :index, podcast.id)
    })
    |> Document.add_embed(%Embed{
      resource: "rad:episode",
      embed: render_many(episodes, EpisodeView, "episode.json", assigns)
    })
  end

  def render("show.json", assigns) do
    render(EpisodeView, "episode.json", assigns)
  end

  def render("episode.json", assigns = %{conn: conn, episode: episode}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_podcast_episode_path(conn, :show, episode.podcast_id, episode)
    })
    |> Document.add_link(%Link{
      rel: "rad:podcast",
      href: Routes.api_podcast_path(assigns.conn, :show, episode.podcast_id)
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
    |> maybe_embed_podcast(episode.podcast, assigns)
    |> maybe_embed_chapters(episode.chapters, assigns)
  end

  defp maybe_embed_podcast(document, %Podcast{} = podcast, assigns) do
    Document.add_embed(document, %Embed{
      resource: "rad:podcast",
      embed: render_one(podcast, PodcastView, "podcast.json", assigns)
    })
  end

  defp maybe_embed_podcast(document, _, _), do: document

  defp maybe_embed_chapters(document, chapters, assigns)
       when is_list(chapters) and length(chapters) > 0 do
    Document.add_embed(document, %Embed{
      resource: "rad:chapter",
      embed: render_many(chapters, ChapterView, "chapter.json", assigns)
    })
  end

  defp maybe_embed_chapters(document, _, _) do
    document
  end
end
