defmodule RadiatorWeb.Controllers.ControllerHelpers do
  def authenticated_user(conn = %Plug.Conn{}) do
    case conn.assigns[:authenticated_user] do
      nil -> nil
      me -> me
    end
  end
end
