defmodule Radiator.Repo.Migrations.CreateNetworks do
  use Ecto.Migration

  def change do
    create table(:networks) do
      add :title, :string

      timestamps(type: :utc_datetime)
    end
  end
end
