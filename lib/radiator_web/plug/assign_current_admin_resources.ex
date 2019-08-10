defmodule RadiatorWeb.Plug.AssignCurrentAdminResources do
  @behaviour Plug

  import RadiatorWeb.Helpers.AdminResourceHelpers, only: [load_current_admin_resources: 1]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    load_current_admin_resources(conn)
  end
end
