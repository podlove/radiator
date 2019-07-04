defmodule RadiatorWeb.Api.FileController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Storage

  def index(conn, _) do
    {:ok, files} = Storage.list_files()
    json(conn, files)
  end

  def show(conn, %{"id" => filename}) do
    {:ok, headers} = Storage.get_file_headers(filename)
    json(conn, headers)
  end
end
