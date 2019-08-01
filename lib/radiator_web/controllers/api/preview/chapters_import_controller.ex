defmodule RadiatorWeb.Api.Preview.ChaptersImportController do
  use RadiatorWeb, :rest_controller

  alias Radiator.AudioMeta.ChapterImport

  defmodule Params do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :data, :string
      field :output_format, :string, default: "json"
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [:data, :output_format])
      |> validate_required(:data)
      |> validate_inclusion(:output_format, ["json", "psc", "mp4chaps"],
        message: ~s(must be one of: json, psc, mp4chaps)
      )
    end
  end

  def convert(conn, params) do
    changeset = Params.changeset(params)

    if changeset.valid? do
      with options <- changeset |> Ecto.Changeset.apply_changes() |> Map.from_struct(),
           {:ok, chapters} <- ChapterImport.import_chapters(options.data) do
        case options.output_format do
          "json" ->
            output =
              Enum.map(chapters, fn c ->
                %{start: c.start, title: c.title, link: c.href, image: c.image}
              end)

            json(conn, output)

          "psc" ->
            output = Chapters.encode(chapters, :psc)

            conn
            |> put_resp_content_type("application/xml", "utf-8")
            |> resp(200, output)

          "mp4chaps" ->
            output = Chapters.encode(chapters, :mp4chaps)

            conn
            |> put_resp_content_type("text/plain")
            |> resp(200, output)
        end
      end
    else
      json(conn, %{errors: RadiatorWeb.ChangesetView.translate_errors(changeset)})
    end
  end
end
