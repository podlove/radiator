defmodule RadiatorWeb.Admin.PodcastView do
  use RadiatorWeb, :view

  import Radiator.Directory.Editor.Permission, only: [has_permission: 3]
  import RadiatorWeb.ContentHelpers

  alias Radiator.Directory.Podcast

  def has_manage_permission_for_podcast(user, subject) do
    has_permission(user, subject, :manage)
  end

  def delete_collaborator_route_builder(conn_or_endpoint, %Podcast{
        id: podcast_id,
        network_id: network_id
      }) do
    &Routes.admin_network_podcast_collaborator_path(
      conn_or_endpoint,
      :delete,
      network_id,
      podcast_id,
      &1
    )
  end
end
