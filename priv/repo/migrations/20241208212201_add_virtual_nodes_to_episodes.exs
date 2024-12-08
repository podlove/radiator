defmodule Radiator.Repo.Migrations.AddVirtualNodesToEpisodes do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add :episode_root_id,
          references(:outline_nodes, on_delete: :delete_all, type: :binary_id, column: :uuid)

      add :episode_inbox_id,
          references(:outline_nodes, on_delete: :delete_all, type: :binary_id, column: :uuid)
    end
  end
end
