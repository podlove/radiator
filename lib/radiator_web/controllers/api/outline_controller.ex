defmodule RadiatorWeb.Api.OutlineController do
  use RadiatorWeb, :controller

  alias Radiator.Outline

  def create(conn, %{"content" => content}) do
    {:ok, node} = Outline.create_node(%{"content" => content})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{uuid: node.uuid}))
  end

  def create(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(%{error: "missing params"}))
  end
end
