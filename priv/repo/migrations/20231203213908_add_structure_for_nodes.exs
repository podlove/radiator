defmodule Radiator.Repo.Migrations.AddStructureForNodes do
  use Ecto.Migration

  def change do
    alter table(:outline_nodes) do
      add :parent_id, :uuid
      add :prev_id, :uuid
    end
  end
end
