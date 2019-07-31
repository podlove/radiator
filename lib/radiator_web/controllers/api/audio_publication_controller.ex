defmodule RadiatorWeb.Api.AudioPublicationController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  plug :assign_network

  # TODO: move this into :rest_controller for all rest controllers
  def action(conn, _) do
    args = [conn, conn.params, current_user(conn)]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, _, user) do
    with {:ok, audio_publications} <- Editor.list_audio_publications(user, conn.assigns[:network]) do
      conn
      |> assign(:audio_publications, audio_publications)
      |> render("index.json")
    end
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

  defp assign_network(conn, _) do
    with {:ok, network} <-
           conn
           |> current_user()
           |> Editor.get_network(conn.params["network_id"]) do
      assign(conn, :network, network)
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
