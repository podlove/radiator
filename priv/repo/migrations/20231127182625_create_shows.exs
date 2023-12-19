defmodule Radiator.Repo.Migrations.CreateShows do
  use Ecto.Migration

  def change do
    create table(:shows) do
      add :title, :string
      add :network_id, references(:networks, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:shows, [:network_id])
  end
end
