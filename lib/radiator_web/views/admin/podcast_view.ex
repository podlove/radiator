defmodule RadiatorWeb.Admin.PodcastView do
  use RadiatorWeb, :view

  def has_manage_permission_for_network(user, subject) do
    Radiator.Directory.Editor.has_permission(user, subject, :manage)
  end
end
