defmodule Radiator.Repo.Migrations.AddTypeInternToNodes do
  use Ecto.Migration

  def change do
    alter table(:outline_nodes) do
      add :_type, :string, default: "node"
    end
  end
end
