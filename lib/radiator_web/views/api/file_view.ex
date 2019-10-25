defmodule RadiatorWeb.Api.FileView do
  use RadiatorWeb, :view

  alias HAL.{Document, Link, Embed}
  alias Radiator.Media.AudioFile

  def render("show.json", assigns) do
    render(__MODULE__, "file.json", assigns)
  end

  def render("file.json", %{conn: conn, file: file}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_file_path(conn, :show, file.id)
    })
    |> Document.add_properties(%{
      id: file.id,
      name: file.name,
      size: file.size,
      mime_type: file.mime_type,
      extension: file.extension
      # url: ...,
      # public_url: ...
    })
  end
end
