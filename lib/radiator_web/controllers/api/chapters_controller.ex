defmodule RadiatorWeb.Api.ChaptersController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  plug :assign_audio when action in [:show, :create, :update, :delete]
  plug :assign_chapter when action in [:show, :update, :delete]

  def show(conn, _params) do
    render(conn, "show.json")
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
    conn
    |> current_user()
    |> Editor.get_audio(conn.params["audio_id"])
    |> case do
      {:ok, audio} ->
        conn
        |> assign(:audio, audio)

      error = {:error, _} ->
        conn
        |> RadiatorWeb.Api.FallbackController.call(error)
        |> halt()
    end
  end

  defp assign_chapter(conn, _) do
    with {:ok, chapter} <-
           Editor.get_chapter(current_user(conn), conn.assigns[:audio], conn.params["start"]) do
      conn
      |> assign(:chapter, chapter)
    else
      error = {:error, _} ->
        conn
        |> RadiatorWeb.Api.FallbackController.call(error)
        |> halt()
    end
  end
end
