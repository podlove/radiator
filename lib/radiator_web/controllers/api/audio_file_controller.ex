defmodule RadiatorWeb.Api.AudioFileController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  # TODO: move this into :rest_controller for all rest controllers
  def action(conn, _) do
    args = [conn, conn.params, current_user(conn)]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, %{"audio_id" => audio_id}, user) do
    with {:ok, audio} <- Editor.get_audio(user, audio_id),
         {:ok, audio_files} <- Editor.list_audio_files(user, audio) do
      conn
      |> assign(:audio_files, audio_files)
      |> render("index.json")
    end
  end

  def create(conn, %{"audio_id" => audio_id, "audio_file" => audio_file_params}, user) do
    with {:ok, audio} <- Editor.get_audio(user, audio_id),
         {:ok, audio_file} <- Editor.create_audio_file(user, audio, audio_file_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.api_audio_file_path(conn, :show, audio_file.audio_id, audio_file)
      )
      |> render("show.json", audio_file: audio_file)
    end
  end

  def show(conn, %{"id" => id}, user) do
    with {:ok, audio_file} <- Editor.get_audio_file(user, id) do
      render(conn, "show.json", audio_file: audio_file)
    end
  end

  def update(conn, %{"id" => id, "audio_file" => audio_file_params}, user) do
    with {:ok, audio_file} <- Editor.get_audio_file(user, id),
         {:ok, audio_file} <- Editor.update_audio_file(user, audio_file, audio_file_params) do
      render(conn, "show.json", audio_file: audio_file)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    with {:ok, audio_file} <- Editor.get_audio_file(user, id),
         {:ok, _} <- Editor.delete_audio_file(user, audio_file) do
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end
end
