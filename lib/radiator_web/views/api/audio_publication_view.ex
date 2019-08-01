defmodule RadiatorWeb.Api.AudioPublicationView do
  use RadiatorWeb, :view

  alias HAL.{Document, Link, Embed}

  def render("index.json", assigns) do
    %Document{}
    # |> Document.add_link(%Link{
    #   rel: "self",
    #   href: Routes.api_podcast_path(assigns.conn, :index)
    # })
    |> Document.add_embed(%Embed{
      resource: "rad:audio_publication",
      embed:
        render_many(assigns.audio_publications, __MODULE__, "audio_publication.json", assigns)
    })
  end

  def render("show.json", assigns) do
    render(__MODULE__, "audio_publication.json", assigns)
  end

  def render("audio_publication.json", assigns = %{audio_publication: audio_publication}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href:
        Routes.api_audio_publication_path(
          assigns.conn,
          :show,
          audio_publication.id
        )
    })
    |> Document.add_properties(%{
      id: audio_publication.id,
      publish_state: audio_publication.publish_state,
      published_at: audio_publication.published_at,
      audio_id: audio_publication.audio_id,
      network_id: audio_publication.network_id
    })
  end
end
