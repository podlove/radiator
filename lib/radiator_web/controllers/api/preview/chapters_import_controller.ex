defmodule RadiatorWeb.Api.Preview.ChaptersImportController do
  use RadiatorWeb, :rest_controller

  alias Radiator.AudioMeta.ChapterImport

  def preview(conn, %{"import_data" => data}) do
    with {:ok, chapters} <- ChapterImport.import_chapters(data),
         chapters <-
           Enum.map(chapters, fn c ->
             %{start: c.start, title: c.title, link: c.href, image: c.image}
           end) do
      conn
      |> json(chapters)
    end
  end
end
