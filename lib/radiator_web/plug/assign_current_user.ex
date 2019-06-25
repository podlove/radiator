defmodule RadiatorWeb.Plug.AssignCurrentUser do
  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    RadiatorWeb.Helpers.AuthHelpers.load_current_user(conn)
  end
end
