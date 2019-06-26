defmodule RadiatorWeb.Api.NetworkController do
  use RadiatorWeb, :controller
  use Radiator.Constants

  alias Radiator.Directory.Editor

  action_fallback RadiatorWeb.Api.FallbackController

  def create(conn, %{"network" => params}) do
    with {:ok, network} <- Editor.create_network(current_user(conn), params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.api_network_path(conn, :show, network)
      )
      |> render("show.json", %{network: network})
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, network} <- Editor.get_network(current_user(conn), id) do
      render(conn, "show.json", %{network: network})
    end
  end
end
