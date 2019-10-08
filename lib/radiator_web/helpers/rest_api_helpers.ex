defmodule RadiatorWeb.Helpers.RestApiHelpers do
  @moduledoc """
  Authentication helper functions for the web layer.
  """

  import Plug.Conn, only: [send_resp: 3]

  def send_delete_resp(conn) do
    conn
    |> send_resp(204, "")
  end

  def send_single_message_success(conn, message \\ "ok") do
    conn
    |> Phoenix.Controller.json(%{result: message})
  end
end
