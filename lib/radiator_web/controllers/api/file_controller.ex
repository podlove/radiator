defmodule RadiatorWeb.Api.FileController do
  use RadiatorWeb, :controller

  alias Radiator.Storage

  action_fallback RadiatorWeb.Api.FallbackController

  def index(conn, _) do
    {:ok, files} = Storage.list_files()
    json(conn, files)
  end

  def show(conn, %{"id" => filename}) do
    {:ok, headers} = Storage.get_file_headers(filename)
    json(conn, headers)
  end
end
