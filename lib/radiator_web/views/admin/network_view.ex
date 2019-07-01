defmodule RadiatorWeb.Admin.NetworkView do
  use RadiatorWeb, :view

  import Radiator.Directory.Editor.Permission, only: [has_permission: 3]
  import RadiatorWeb.ContentHelpers

  alias Radiator.Directory.Network

  def has_edit_permission_for_network(user, subject) do
    has_permission(user, subject, :own)
  end

  def has_manage_permission_for_network(user, subject) do
    has_permission(user, subject, :manage)
  end

  def delete_collaborator_route_builder(conn_or_endpoint, %Network{
        id: network_id
      }) do
    &Routes.admin_network_collaborator_path(
      conn_or_endpoint,
      :delete,
      network_id,
      &1
    )
  end
end
