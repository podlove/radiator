defmodule RadiatorWeb.Api.FileController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  def create(conn, params = %{"network_id" => network_id}) do
    with user = current_user(conn),
         {:ok, network} <- Editor.get_network(user, network_id),
         {:ok, file} <-
           Editor.create_file(
             user,
             network,
             Map.get(params, "file")
           ) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_file_path(conn, :show, file))
      |> render("show.json", %{file: file})
    end
  end

  def show(conn, %{"id" => id}) do
    with user = current_user(conn),
         {:ok, file} <- Editor.get_file(user, id) do
      render(conn, "show.json", %{file: file})
    end
  end
end
