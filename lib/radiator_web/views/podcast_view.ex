defmodule RadiatorWeb.PodcastView do
  use RadiatorWeb, :view
  alias RadiatorWeb.PodcastView

  def render("index.json", %{podcasts: podcasts}) do
    %{data: render_many(podcasts, PodcastView, "podcast.json")}
  end

  def render("show.json", %{podcast: podcast}) do
    %{data: render_one(podcast, PodcastView, "podcast.json")}
  end

  def render("podcast.json", %{podcast: podcast}) do
    %{id: podcast.id,
      title: podcast.title,
      subtitle: podcast.subtitle,
      description: podcast.description,
      image: podcast.image,
      author: podcast.author,
      owner_name: podcast.owner_name,
      owner_email: podcast.owner_email,
      language: podcast.language,
      published_at: podcast.published_at,
      last_built_at: podcast.last_built_at}
  end
end
