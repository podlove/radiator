defmodule Radiator.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add :title, :string
      add :subtitle, :string
      add :description, :string
      add :content, :string
      add :image, :string
      add :enclosure_url, :string
      add :enclosure_length, :string
      add :enclosure_type, :string
      add :duration, :string
      add :guid, :string
      add :number, :integer
      add :published_at, :utc_datetime
      add :podcast_id, references(:podcasts, on_delete: :nothing)

      timestamps()
    end

    create index(:episodes, [:podcast_id])
  end
end
