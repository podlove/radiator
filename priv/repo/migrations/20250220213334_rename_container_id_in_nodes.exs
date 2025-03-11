defmodule Radiator.Repo.Migrations.RenameContainerIdInNodes do
  use Ecto.Migration

  def change do
    rename table("outline_nodes"), :outline_node_container_id, to: :container_id
  end
end
