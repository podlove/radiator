defmodule Radiator.Repo.Migrations.AddVirtualNodesToShows do
  use Ecto.Migration

  def change do
    alter table(:shows) do
      add :global_root_id,
          references(:outline_nodes, on_delete: :delete_all, type: :binary_id, column: :uuid)

      add :global_inbox_id,
          references(:outline_nodes, on_delete: :delete_all, type: :binary_id, column: :uuid)
    end
  end
end
