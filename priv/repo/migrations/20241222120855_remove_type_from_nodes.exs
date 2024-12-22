defmodule Radiator.Repo.Migrations.RemoveTypeFromNodes do
  use Ecto.Migration

  def change do
    alter table(:outline_nodes) do
      remove :_type, :string, default: "node"
    end
  end
end
