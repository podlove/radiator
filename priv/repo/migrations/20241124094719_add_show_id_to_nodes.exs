defmodule Radiator.Repo.Migrations.AddShowIdToNodes do
  use Ecto.Migration

  def change do
    alter table(:outline_nodes) do
      add :show_id, references(:shows, on_delete: :nothing)
    end

    create index(:outline_nodes, [:show_id])
  end
end
