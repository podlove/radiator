defmodule RadiatorWeb.Api.AudioFileView do
  use RadiatorWeb, :view

  alias HAL.{Document, Link, Embed}
  alias Radiator.Media.AudioFile

  def render("index.json", assigns = %{audio_files: audio_files}) do
    %Document{}
    |> Document.add_embed(%Embed{
      resource: "rad:audio_file",
      embed: render_many(audio_files, __MODULE__, "audio_file.json", assigns)
    })
  end

  def render("show.json", assigns) do
    render(__MODULE__, "audio_file.json", assigns)
  end

  def render("audio_file.json", %{conn: conn, audio_file: audio_file}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_audio_file_path(conn, :show, audio_file.audio_id, audio_file.id)
    })
    |> Document.add_properties(%{
      id: audio_file.id,
      title: audio_file.title,
      byte_length: audio_file.byte_length,
      mime_type: audio_file.mime_type,
      url: AudioFile.internal_url(audio_file),
      public_url: AudioFile.public_url(audio_file)
    })
  end
end
