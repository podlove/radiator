defmodule RadiatorWeb.GuardianApiErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    send_resp(conn, 401, "Unauthorized")
  end
end
