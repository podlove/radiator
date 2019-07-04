defmodule RadiatorWeb.Api.NetworkController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  def create(conn, %{"network" => params}) do
    with user = current_user(conn),
         {:ok, network} <- Editor.create_network(user, params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_network_path(conn, :show, network))
      |> render("show.json", %{network: network})
    end
  end

  def show(conn, %{"id" => id}) do
    with user = current_user(conn),
         {:ok, network} <- Editor.get_network(user, id) do
      render(conn, "show.json", %{network: network})
    end
  end

  def update(conn, %{"id" => id, "network" => network_params}) do
    with user = current_user(conn),
         {:ok, network} <- Editor.get_network(user, id),
         {:ok, network} <- Editor.update_network(user, network, network_params) do
      render(conn, "show.json", %{network: network})
    end
  end

  def delete(conn, %{"id" => id}) do
    with user <- current_user(conn),
         {:ok, network} <- Editor.get_network(user, id),
         {:ok, _} <- Editor.delete_network(user, network) do
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end
end
