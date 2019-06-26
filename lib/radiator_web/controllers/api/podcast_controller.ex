defmodule RadiatorWeb.Api.PodcastController do
  use RadiatorWeb, :controller
  use Radiator.Constants

  alias Radiator.Directory.Editor

  action_fallback RadiatorWeb.Api.FallbackController

  def create(conn, %{"podcast" => params}) do
    with user = current_user(conn),
         {:ok, network} <- Editor.get_network(user, params["network_id"]),
         {:ok, podcast} <- Editor.create_podcast(user, network, params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_podcast_path(conn, :show, podcast))
      |> render("show.json", %{podcast: podcast})
    end
  end

  def show(conn, %{"id" => id}) do
    with user = current_user(conn),
         {:ok, podcast} <- Editor.get_podcast(user, id) do
      render(conn, "show.json", %{podcast: podcast})
    end
  end

  def update(conn, %{"id" => id, "podcast" => podcast_params}) do
    with user = current_user(conn),
         {:ok, podcast} <- Editor.get_podcast(user, id),
         {:ok, podcast} <- Editor.update_podcast(user, podcast, podcast_params) do
      render(conn, "show.json", %{podcast: podcast})
    end
  end

  def delete(conn, %{"id" => id}) do
    with user <- current_user(conn),
         {:ok, podcast} <- Editor.get_podcast(user, id),
         {:ok, _} <- Editor.delete_podcast(user, podcast) do
      send_resp(conn, 204, "")
    end
  end
end
