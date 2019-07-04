defmodule RadiatorWeb.Api.EpisodeController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  def create(conn, %{"episode" => params}) do
    with user = current_user(conn),
         {:ok, podcast} <- Editor.get_podcast(user, params["podcast_id"]),
         {:ok, episode} <- Editor.create_episode(user, podcast, params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_episode_path(conn, :show, episode))
      |> render("show.json", %{episode: episode})
    end
  end

  def show(conn, %{"id" => id}) do
    with user = current_user(conn),
         {:ok, episode} <- Editor.get_episode(user, id) do
      render(conn, "show.json", %{episode: episode})
    end
  end

  def update(conn, %{"id" => id, "episode" => episode_params}) do
    with user = current_user(conn),
         {:ok, episode} <- Editor.get_episode(user, id),
         {:ok, episode} <- Editor.update_episode(user, episode, episode_params) do
      render(conn, "show.json", %{episode: episode})
    end
  end

  def delete(conn, %{"id" => id}) do
    with user <- current_user(conn),
         {:ok, episode} <- Editor.get_episode(user, id),
         {:ok, _} <- Editor.delete_episode(user, episode) do
          send_delete_resp(conn)
        end
  end
end
