defmodule Radiator.Repo.Migrations.CreateOutlineNodeContainers do
  use Ecto.Migration

  def change do
    create table(:outline_node_containers) do
      timestamps(type: :utc_datetime)
    end

    alter table(:outline_nodes) do
      add :outline_node_container_id, references(:outline_node_containers, on_delete: :delete_all)
    end

    create index(:outline_nodes, [:outline_node_container_id])
  end
end
