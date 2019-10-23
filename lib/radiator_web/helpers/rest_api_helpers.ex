defmodule RadiatorWeb.Helpers.RestApiHelpers do
  @moduledoc """
  Authentication helper functions for the web layer.
  """

  import Plug.Conn, only: [send_resp: 3]

  def send_delete_resp(conn) do
    send_no_content(conn)
  end

  def send_no_content(conn) do
    send_resp(conn, 204, "")
  end

  def send_single_message_success(conn, message \\ "ok") do
    conn
    |> Phoenix.Controller.json(%{result: message})
  end
end
