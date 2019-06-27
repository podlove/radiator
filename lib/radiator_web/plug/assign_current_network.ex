defmodule RadiatorWeb.Plug.AssignCurrentNetwork do
  @behaviour Plug

  import Plug.Conn
  import Radiator.Directory, only: [get_network: 1]
  import Radiator.Directory.Editor.Permission, only: [has_permission: 3]

  alias RadiatorWeb.Router.Helpers, as: Routes

  @impl Plug
  def init(opts), do: opts

  def user_has_permission(user, network, permission) do
    has_permission(user, network, permission)
  end

  @impl Plug
  def call(conn, _opts) do
    case Map.get(conn.path_params, "network_id") do
      nil ->
        conn

      network_id when is_binary(network_id) ->
        network =
          network_id
          |> String.to_integer()
          |> get_network()

        user = conn.assigns.current_user

        if user_has_permission(user, network, :readonly) do
          assign(
            conn,
            :current_network,
            network
          )
        else
          conn
          |> Phoenix.Controller.put_flash(
            :error,
            "Account #{user.name} is not authorized for this resource."
          )
          |> Phoenix.Controller.redirect(to: Routes.admin_network_path(conn, :index))
          |> halt()
        end
    end
  end
end
