defmodule Radiator.Repo.Migrations.CreateUrls do
  use Ecto.Migration

  def change do
    create table(:urls) do
      add :url, :string
      add :start_bytes, :integer
      add :size_bytes, :integer

      add :node_id,
          references(:outline_nodes, on_delete: :nothing, type: :binary_id, column: :uuid)

      timestamps(type: :utc_datetime)
    end

    create index(:urls, [:node_id])
  end
end
