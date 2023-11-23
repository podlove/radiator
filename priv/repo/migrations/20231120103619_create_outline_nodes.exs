defmodule Radiator.Repo.Migrations.CreateOutlineNodes do
  use Ecto.Migration

  def change do
    create table(:outline_nodes, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :content, :text

      timestamps(type: :utc_datetime)
    end
  end
end
