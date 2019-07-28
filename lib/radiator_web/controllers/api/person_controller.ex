defmodule RadiatorWeb.Api.PersonController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor
  alias Radiator.Directory.Network

  require Logger

  # TODO: move this into :rest_controller for all rest controllers
  def action(conn, _) do
    args = [conn, conn.params, current_user(conn)]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, params, user) do
    with network_id <- params["person"]["network_id"],
         {:ok, people} <- Editor.get_people(user, %Network{id: network_id}) do
      conn
      |> render("index.json", %{people: people})
    else
      _ -> @not_found_match
    end
  end

  def create(conn, %{"person" => params}, user) do
    with {:ok, network} <- Editor.get_network(user, params["network_id"]),
         {:ok, person} <- Editor.create_person(user, network, params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_person_path(conn, :show, person))
      |> render("show.json", %{person: person})
    end
  end

  def show(conn, %{"id" => id}, user) do
    with {:ok, person} <- Editor.get_person(user, id) do
      conn
      |> render("show.json", %{person: person})
    end
  end

  def update(conn, %{"id" => id, "person" => person_params}, user) do
    with {:ok, person} <- Editor.get_person(user, id),
         {:ok, person} <- Editor.update_person(user, person, person_params) do
      conn
      |> render("show.json", %{person: person})
    end
  end

  def delete(conn, %{"id" => id}, user) do
    with {:ok, person} <- Editor.get_person(user, id),
         {:ok, _} <- Editor.delete_person(user, person) do
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end
end
