defmodule RadiatorWeb.GuardianApiErrorHandler do
  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    RadiatorWeb.Api.FallbackController.call(conn, {:error, :not_authorized})
  end
end
