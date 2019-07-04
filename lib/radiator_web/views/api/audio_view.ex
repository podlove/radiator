defmodule RadiatorWeb.Api.AudioView do
  use RadiatorWeb, :view
  alias RadiatorWeb.Api.AudioView
  alias HAL.{Document, Link}

  def render("show.json", assigns) do
    render(AudioView, "audio.json", assigns)
  end

  def render("audio.json", assigns = %{audio: audio}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_audio_path(assigns.conn, :show, audio.id)
    })
    |> Document.add_properties(%{
      id: audio.id,
      title: audio.title,
      duration: audio.duration,
      published_at: audio.published_at
    })
  end
end