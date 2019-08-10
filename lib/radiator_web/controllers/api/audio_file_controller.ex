defmodule RadiatorWeb.Api.AudioFileController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  plug :assign_audio when action in [:index, :create]

  # TODO: move this into :rest_controller for all rest controllers
  def action(conn, _) do
    args = [conn, conn.params, current_user(conn)]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, _, user) do
    with {:ok, audio_files} <- Editor.list_audio_files(user, conn.assigns[:audio]) do
      conn
      |> assign(:audio_files, audio_files)
      |> render("index.json")
    end
  end

  def create(conn, %{"audio_file" => audio_file_params}, user) do
    with {:ok, audio_file} <-
           Editor.create_audio_file(user, conn.assigns[:audio], audio_file_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.api_audio_file_path(conn, :show, audio_file)
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

  defp apply_action_fallback(conn, response) do
    case @phoenix_fallback do
      {:module, module} -> apply(module, :call, [conn, response]) |> halt()
    end
  end
end
