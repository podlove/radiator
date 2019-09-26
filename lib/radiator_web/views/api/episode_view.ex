defmodule RadiatorWeb.Api.EpisodeView do
  use RadiatorWeb, :view

  alias HAL.{
    Document,
    Link,
    Embed
  }

  alias Radiator.Directory.{
    Episode,
    Podcast
  }

  alias RadiatorWeb.Api.{
    EpisodeView,
    PodcastView
  }

  import RadiatorWeb.ContentHelpers

  def render("show.json", assigns) do
    render(EpisodeView, "episode.json", assigns)
  end

  def render("episode.json", assigns = %{conn: conn, episode: episode}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_episode_path(conn, :show, episode.id)
    })
    |> Document.add_link(%Link{
      rel: "rad:podcast",
      href: Routes.api_podcast_path(assigns.conn, :show, episode.podcast_id)
    })
    |> Document.add_properties(%{
      id: episode.id,
      guid: episode.guid,
      title: episode.title,
      subtitle: episode.subtitle,
      summary: episode.summary,
      summary_html: episode.summary_html,
      summary_source: episode.summary_source,
      image: episode_image_url(episode),
      number: episode.number,
      published_at: episode.published_at,
      publish_state: episode.publish_state
    })
    |> maybe_embed_podcast(episode.podcast, assigns)
  end

  def render("enclosure.json", %{episode: episode}) do
    %Document{}
    |> Document.add_properties(%{
      url: Episode.enclosure_url(episode),
      length: episode.enclosure.byte_length,
      type: episode.enclosure.mime_type
    })
  end

  defp maybe_embed_podcast(document, %Podcast{} = podcast, assigns) do
    Document.add_embed(document, %Embed{
      resource: "rad:podcast",
      embed: render_one(podcast, PodcastView, "podcast.json", assigns)
    })
  end

  defp maybe_embed_podcast(document, _, _), do: document
end
