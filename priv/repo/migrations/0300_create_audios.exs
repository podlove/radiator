defmodule Radiator.Repo.Migrations.CreateAudios do
  use Ecto.Migration

  def change do
    create table(:audios) do
      add :title, :text
      add :duration, :text
      add :image, :string
      add :published_at, :utc_datetime

      add :network_id, references(:networks, on_delete: :nothing)

      timestamps()
    end

    create index(:audios, [:network_id])
  end
end
