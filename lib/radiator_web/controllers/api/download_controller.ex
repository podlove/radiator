defmodule RadiatorWeb.Api.DownloadController do
  use RadiatorWeb, :controller

  alias Radiator.Storage

  action_fallback RadiatorWeb.Api.FallbackController

  def show(conn, %{"id" => filename}) do
    {:ok, body, headers} = Storage.get_file(filename)

    conn
    |> put_resp_content_type(Map.get(headers, "Content-Type"))
    |> send_resp(200, body)
  end
end
