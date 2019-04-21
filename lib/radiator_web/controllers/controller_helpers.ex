defmodule RadiatorWeb.Controllers.ControllerHelpers do
  def get_me(conn = %Plug.Conn{}) do
    case conn.assigns[:authenticated_user] do
      nil -> nil
      me -> me
    end
  end
end
