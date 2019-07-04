defmodule RadiatorWeb.Api.ChaptersController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  def create(conn, %{"audio_id" => audio_id, "chapter" => chapter_params}) do
    with user <- current_user(conn),
         {:ok, audio} <- Editor.get_audio(user, audio_id),
         {:ok, chapter} <- Editor.create_chapter(user, audio, chapter_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.api_audio_chapters_path(conn, :show, audio.id, chapter)
      )
      |> assign(:audio, audio)
      |> assign(:chapter, chapter)
      |> render("show.json")
    end
  end

  def update(conn, %{"audio_id" => audio_id, "id" => id, "chapter" => chapter_params}) do
    with user <- current_user(conn),
         {:ok, audio} <- Editor.get_audio(user, audio_id),
         {:ok, chapter} <- Editor.get_chapter(user, id),
         {:ok, chapter} <- Editor.update_chapter(user, chapter, chapter_params) do
      conn
      |> assign(:audio, audio)
      |> assign(:chapter, chapter)
      |> render("show.json")
    end
  end

  def delete(conn, %{"id" => id}) do
    with user <- current_user(conn),
         {:ok, chapter} <- Editor.get_chapter(user, id),
         {:ok, _} <- Editor.delete_chapter(user, chapter) do
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end
end
