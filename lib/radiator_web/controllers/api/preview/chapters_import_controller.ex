defmodule RadiatorWeb.Api.Preview.ChaptersImportController do
  use RadiatorWeb, :rest_controller

  alias Radiator.AudioMeta.ChapterImport

  import RadiatorWeb.FormatHelpers, only: [format_normal_playtime: 1]

  def convert(conn, %{"data" => data}) do
    with {:ok, chapters} <- ChapterImport.import_chapters(data) do
      output =
        Enum.map(chapters, fn c ->
          %{
            start: c.start,
            start_string: format_normal_playtime(c.start),
            title: c.title,
            link: c.href,
            image: c.image
          }
        end)

      json(conn, output)
    end
  end

  def convert(_, _) do
    {:error, :unprocessable}
  end
end
