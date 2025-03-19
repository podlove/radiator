defmodule Radiator.Repo.Migrations.RemoveOutlineContainerIdFromShow do
  use Ecto.Migration

  def change do
    alter table(:shows) do
      remove :outline_node_container_id, references(:outline_node_containers, on_delete: :nothing)
    end
  end
end
