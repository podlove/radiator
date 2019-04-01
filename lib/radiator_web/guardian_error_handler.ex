defmodule RadiatorWeb.GuardianErrorHandler do
  import Plug.Conn
  alias RadiatorWeb.Router.Helpers, as: Routes

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, _opts) do
    conn
    |> put_session(:on_login, {conn.request_path, conn.query_string})
    |> Phoenix.Controller.put_flash(:info, "Needs login")
    |> Phoenix.Controller.redirect(to: Routes.login_path(conn, :login_form))
  end
end
