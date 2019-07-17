defmodule RadiatorWeb.Api.PodcastView do
  use RadiatorWeb, :view
  alias RadiatorWeb.Api.PodcastView
  alias HAL.{Document, Link, Embed}

  def render("index.json", assigns = %{podcasts: podcasts}) do
    %Document{}
    # |> Document.add_link(%Link{
    #   rel: "self",
    #   href: Routes.api_podcast_path(assigns.conn, :index)
    # })
    |> Document.add_embed(%Embed{
      resource: "rad:podcast",
      embed: render_many(podcasts, PodcastView, "podcast.json", assigns)
    })
  end

  def render("show.json", assigns) do
    render(PodcastView, "podcast.json", assigns)
  end

  def render("podcast.json", assigns = %{podcast: podcast}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_podcast_path(assigns.conn, :show, podcast.id)
    })
    # |> Document.add_link(%Link{
    #   rel: "rad:episodes",
    #   href: Routes.api_episode_path(assigns.conn, :index, podcast.id)
    # })
    |> Document.add_properties(%{
      id: podcast.id,
      short_id: podcast.short_id,
      title: podcast.title,
      subtitle: podcast.subtitle,
      summary: podcast.summary,
      author: podcast.author,
      image: podcast.image,
      language: podcast.language,
      last_built_at: podcast.last_built_at,
      owner_name: podcast.owner_name,
      owner_email: podcast.owner_email,
      published_at: podcast.published_at,
      slug: podcast.slug
    })
  end
end
