defmodule Radiator.Repo.Migrations.RemoveInboxContainerIdFromEpisode do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      remove :inbox_node_container_id, references(:outline_node_containers, on_delete: :nothing)
    end
  end
end
