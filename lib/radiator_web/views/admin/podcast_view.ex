defmodule RadiatorWeb.Admin.PodcastView do
  use RadiatorWeb, :view

  import Radiator.Auth.Permission, only: [has_permission: 3]

  def has_manage_permission_for_network(user, subject) do
    has_permission(user, subject, :manage)
  end
end
