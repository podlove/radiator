defmodule RadiatorWeb.Api.ChaptersController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  plug :assign_audio when action in [:index, :show, :create, :update, :delete]
  plug :assign_chapter when action in [:show, :update, :delete]

  defmodule Params do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :format, :string, default: "rest"
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [:format])
      |> validate_inclusion(:format, ["rest", "json", "psc", "mp4chaps"],
        message: ~s(must be one of: rest, json, psc, mp4chaps)
      )
    end
  end

  def show(conn, _params) do
    render(conn, "show.json")
  end

  def index(conn, params) do
    with user <- current_user(conn),
         {:ok, chapters} <- Editor.list_chapters(user, conn.assigns[:audio]),
         changeset <- Params.changeset(params),
         options <- changeset |> Ecto.Changeset.apply_changes() |> Map.from_struct() do
      if changeset.valid? do
        case options.format do
          "rest" ->
            conn
            |> assign(:chapters, chapters)
            |> render("index.json")

          "json" ->
            chapters = convert_chapters(chapters)

            output =
              Enum.map(chapters, fn c ->
                %{start: c.start, title: c.title, link: c.href, image: c.image}
              end)

            json(conn, output)

          "psc" ->
            chapters = convert_chapters(chapters)
            output = Chapters.encode(chapters, :psc)

            conn
            |> put_resp_content_type("application/xml", "utf-8")
            |> resp(200, output)

          "mp4chaps" ->
            chapters = convert_chapters(chapters)
            output = Chapters.encode(chapters, :mp4chaps)

            conn
            |> put_resp_content_type("text/plain")
            |> resp(200, output)
        end
      else
        json(conn, %{errors: RadiatorWeb.ChangesetView.translate_errors(changeset)})
      end
    end
  end

  # convert list of chapters for chapters package
  defp convert_chapters(chapters) do
    Enum.map(chapters, fn chapter ->
      %Chapters.Chapter{
        href: chapter.link,
        image: Radiator.AudioMeta.Chapter.image_url(chapter),
        start: chapter.start,
        title: chapter.title
      }
    end)
  end

  def create(conn, %{"chapter" => chapter_params}) do
    with user <- current_user(conn),
         {:ok, chapter} <- Editor.create_chapter(user, conn.assigns[:audio], chapter_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.api_audio_chapters_path(conn, :show, conn.assigns[:audio].id, chapter.start)
      )
      |> assign(:chapter, chapter)
      |> render("show.json")
    end
  end

  def update(conn, %{"chapter" => chapter_params}) do
    with user <- current_user(conn),
         {:ok, chapter} <- Editor.update_chapter(user, conn.assigns[:chapter], chapter_params) do
      conn
      |> assign(:chapter, chapter)
      |> render("show.json")
    end
  end

  def delete(conn, _) do
    with user <- current_user(conn),
         {:ok, _} <- Editor.delete_chapter(user, conn.assigns[:chapter]) do
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end

  defp assign_audio(conn, _) do
    with {:ok, audio} <-
           conn
           |> current_user()
           |> Editor.get_audio(conn.params["audio_id"]) do
      conn
      |> assign(:audio, audio)
    else
      response -> apply_action_fallback(conn, response)
    end
  end

  defp assign_chapter(conn, _) do
    with {:ok, chapter} <-
           conn
           |> current_user()
           |> Editor.get_chapter(conn.assigns[:audio], conn.params["start"]) do
      conn
      |> assign(:chapter, chapter)
    else
      response -> apply_action_fallback(conn, response)
    end
  end

  defp apply_action_fallback(conn, response) do
    case @phoenix_fallback do
      {:module, module} -> apply(module, :call, [conn, response]) |> halt()
    end
  end
end
