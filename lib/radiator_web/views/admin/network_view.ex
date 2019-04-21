defmodule RadiatorWeb.Admin.NetworkView do
  use RadiatorWeb, :view

  def has_edit_permission_for_network(user, subject) do
    Radiator.Directory.Editor.has_permission(user, subject, :own)
  end
end
