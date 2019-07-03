defmodule RadiatorWeb.Api.AudioController do
  use RadiatorWeb, :controller
  use Radiator.Constants

  alias Radiator.Directory.Editor

  action_fallback RadiatorWeb.Api.FallbackController

  def create(conn, %{"audio" => params = %{"network_id" => network_id}}) do
    with user = current_user(conn),
         {:ok, network} <- Editor.get_network(user, network_id),
         {:ok, audio} <- Editor.create_audio(user, network, params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_audio_path(conn, :show, audio))
      |> render("show.json", %{audio: audio})
    end
  end

  def create(conn, %{"audio" => params = %{"episode_id" => episode_id}}) do
    with user = current_user(conn),
         {:ok, episode} <- Editor.get_episode(user, episode_id),
         {:ok, audio} <- Editor.create_audio(user, episode, params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_audio_path(conn, :show, audio))
      |> render("show.json", %{audio: audio})
    end
  end

  def create(conn, %{"audio" => _}) do
    conn
    |> put_status(422)
    |> json(%{"errors" => %{"assignment" => "Either episode_id or network_id must be present."}})
  end

  def show(conn, %{"id" => id}) do
    with user = current_user(conn),
         {:ok, audio} <- Editor.get_audio(user, id) do
      render(conn, "show.json", %{audio: audio})
    end
  end

  def update(conn, %{"id" => id, "audio" => audio_params}) do
    with user = current_user(conn),
         {:ok, audio} <- Editor.get_audio(user, id),
         {:ok, audio} <- Editor.update_audio(user, audio, audio_params) do
      render(conn, "show.json", %{audio: audio})
    end
  end

  def delete(conn, %{"id" => id}) do
    with user <- current_user(conn),
         {:ok, audio} <- Editor.get_audio(user, id),
         {:ok, _} <- Editor.delete_audio(user, audio) do
      send_resp(conn, 204, "")
    end
  end
end
