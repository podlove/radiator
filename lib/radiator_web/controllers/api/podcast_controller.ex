defmodule RadiatorWeb.Api.PodcastController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

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
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end

  def publish(conn, %{"podcast_id" => id}) do
    with user = current_user(conn),
         {:ok, podcast} <- Editor.get_podcast(user, id),
         {:ok, _podcast} <- Editor.publish_podcast(user, podcast) do
      send_no_content(conn)
    end
  end

  def depublish(conn, %{"podcast_id" => id}) do
    with user = current_user(conn),
         {:ok, podcast} <- Editor.get_podcast(user, id),
         {:ok, _podcast} <- Editor.depublish_podcast(user, podcast) do
      send_no_content(conn)
    end
  end
end
