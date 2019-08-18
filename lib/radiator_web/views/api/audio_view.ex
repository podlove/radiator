defmodule RadiatorWeb.Api.AudioView do
  use RadiatorWeb, :view
  alias RadiatorWeb.Api.AudioView
  alias HAL.{Document, Link}
  import RadiatorWeb.FormatHelpers, only: [format_normal_playtime: 1]
  import RadiatorWeb.ContentHelpers

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
      duration: audio.duration,
      duration_string: audio.duration && format_normal_playtime(audio.duration),
      image: audio_image_url(audio)
    })
  end
end
