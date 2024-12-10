defmodule Radiator.Repo.Migrations.AddNodeContainers do
  use Ecto.Migration

  def change do
    alter table(:shows) do
      add :inbox_node_container_id, references(:outline_node_containers, on_delete: :delete_all)
      add :outline_node_container_id, references(:outline_node_containers, on_delete: :delete_all)
    end

    alter table(:episodes) do
      add :inbox_node_container_id, references(:outline_node_containers, on_delete: :delete_all)
      add :outline_node_container_id, references(:outline_node_containers, on_delete: :delete_all)
    end
  end
end
