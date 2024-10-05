defmodule Radiator.Repo.Migrations.AddDescriptionToShow do
  use Ecto.Migration

  def change do
    alter table(:shows) do
      add :description, :string
    end
  end
end
