defmodule RadiatorWeb.Admin.NetworkView do
  use RadiatorWeb, :view

  import Radiator.Directory.Editor.Permission, only: [has_permission: 3]
  import RadiatorWeb.ContentHelpers

  def has_edit_permission_for_network(user, subject) do
    has_permission(user, subject, :own)
  end

  def has_manage_permission_for_network(user, subject) do
    has_permission(user, subject, :manage)
  end
end
