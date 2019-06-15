defmodule RadiatorWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use RadiatorWeb, :controller

  require Logger

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(RadiatorWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, other) do
    Logger.error(inspect({:unhandled_error, other}, pretty: true))

    conn
    |> put_status(:not_found)
    |> put_view(RadiatorWeb.ErrorView)
    |> render(:"404")
  end
end
