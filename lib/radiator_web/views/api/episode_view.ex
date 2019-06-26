defmodule RadiatorWeb.Api.EpisodeView do
  use RadiatorWeb, :view
  alias RadiatorWeb.Api.{ChapterView, EpisodeView, PodcastView}

  alias HAL.{Document, Link, Embed}
  alias Radiator.Directory.{Episode, Podcast, Audio}

  def render("index.json", assigns = %{podcast: podcast, episodes: episodes}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_episode_path(assigns.conn, :index, podcast.id)
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
      href: Routes.api_episode_path(conn, :show, episode.podcast_id, episode)
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
      guid: episode.guid,
      number: episode.number,
      published_at: episode.published_at
    })
    |> maybe_add_duration(episode, assigns)
    |> maybe_embed_enclosure(episode, assigns)
    |> maybe_embed_podcast(episode.podcast, assigns)
    |> maybe_embed_chapters(episode.audio, assigns)
  end

  def render("enclosure.json", %{episode: episode}) do
    %Document{}
    |> Document.add_properties(%{
      url: Episode.enclosure_url(episode),
      length: episode.enclosure.byte_length,
      type: episode.enclosure.mime_type
    })
  end

  def maybe_add_duration(document, %Episode{audio: %Audio{duration: duration}}, _) do
    Document.add_properties(document, %{duration: duration})
  end

  def maybe_add_duration(document, _, _) do
    document
  end

  defp maybe_embed_podcast(document, %Podcast{} = podcast, assigns) do
    Document.add_embed(document, %Embed{
      resource: "rad:podcast",
      embed: render_one(podcast, PodcastView, "podcast.json", assigns)
    })
  end

  defp maybe_embed_podcast(document, _, _), do: document

  defp maybe_embed_chapters(document, %Audio{chapters: chapters}, assigns)
       when is_list(chapters) and length(chapters) > 0 do
    Document.add_embed(document, %Embed{
      resource: "rad:chapter",
      embed: render_many(chapters, ChapterView, "chapter.json", assigns)
    })
  end

  defp maybe_embed_chapters(document, _, _) do
    document
  end

  defp maybe_embed_enclosure(document, episode, _assigns) do
    if Ecto.assoc_loaded?(episode.audio) && episode.audio do
      Document.add_embed(document, %Embed{
        resource: "rad:enclosure",
        embed:
          %Document{}
          |> Document.add_properties(%{
            url: Episode.enclosure_url(episode),
            length: Episode.enclosure_byte_length(episode),
            type: Episode.enclosure_mime_type(episode)
          })
      })
    else
      document
    end
  end
end
