defmodule Radiator.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add :title, :string
      add :show_id, references(:shows, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:episodes, [:show_id])
  end
end
