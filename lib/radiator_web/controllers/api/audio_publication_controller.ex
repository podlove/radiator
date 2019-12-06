defmodule RadiatorWeb.Api.AudioPublicationController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  # TODO: move this into :rest_controller for all rest controllers
  def action(conn, _) do
    args = [conn, conn.params, current_user(conn)]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, %{"network_id" => network_id}, user) do
    with {:ok, network} <- Editor.get_network(user, network_id),
         {:ok, audio_publications} <- Editor.list_audio_publications(user, network) do
      conn
      |> assign(:network, network)
      |> assign(:audio_publications, audio_publications)
      |> render("index.json")
    end
  end

  def index(conn, _, _) do
    conn
    |> put_status(422)
    |> json(%{"errors" => %{"network_id" => "network_id parameter must be present."}})
  end

  def show(conn, %{"id" => id}, user) do
    with {:ok, audio_publication} <- Editor.get_audio_publication(user, id) do
      conn
      |> assign(:audio_publication, audio_publication)
      |> render("show.json")
    end
  end

  def update(conn, %{"id" => id, "audio_publication" => audio_publication_params}, user) do
    with {:ok, audio_publication} <- Editor.get_audio_publication(user, id),
         {:ok, audio_publication} <-
           Editor.update_audio_publication(user, audio_publication, audio_publication_params) do
      conn
      |> assign(:audio_publication, audio_publication)
      |> render("show.json")
    end
  end

  def delete(conn, %{"id" => id}, user) do
    with {:ok, audio_publication} <- Editor.get_audio_publication(user, id),
         {:ok, _} <- Editor.delete_audio_publication(user, audio_publication) do
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end

  def publish(conn, %{"audio_publication_id" => id}, user) do
    with {:ok, audio_publication} <- Editor.get_audio_publication(user, id),
         {:ok, _audio_publication} <- Editor.publish_audio_publication(user, audio_publication) do
      send_no_content(conn)
    end
  end

  def depublish(conn, %{"audio_publication_id" => id}, user) do
    with {:ok, audio_publication} <- Editor.get_audio_publication(user, id),
         {:ok, _audio_publication} <- Editor.depublish_audio_publication(user, audio_publication) do
      send_no_content(conn)
    end
  end
end
