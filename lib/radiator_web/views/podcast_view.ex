defmodule RadiatorWeb.PodcastView do
  use RadiatorWeb, :view
  alias RadiatorWeb.PodcastView
  alias HAL.{Document, Link}

  def render("index.json", assigns = %{podcasts: podcasts}) do
    %{data: render_many(podcasts, PodcastView, "podcast.json", assigns)}
  end

  def render("show.json", assigns) do
    %{data: render(PodcastView, "podcast.json", assigns)}
  end

  def render("podcast.json", assigns = %{podcast: podcast}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.podcast_path(assigns.conn, :show, podcast.id)
    })
    |> Document.add_properties(%{
      id: podcast.id,
      title: podcast.title,
      subtitle: podcast.subtitle,
      description: podcast.description,
      image: podcast.image,
      author: podcast.author,
      owner_name: podcast.owner_name,
      owner_email: podcast.owner_email,
      language: podcast.language,
      published_at: podcast.published_at,
      last_built_at: podcast.last_built_at
    })
  end
end
