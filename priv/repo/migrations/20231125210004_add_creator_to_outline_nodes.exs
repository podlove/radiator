defmodule Radiator.Repo.Migrations.AddCreatorToOutlineNodes do
  use Ecto.Migration

  def change do
    alter table(:outline_nodes) do
      add :creator_id, :integer
    end
  end
end
