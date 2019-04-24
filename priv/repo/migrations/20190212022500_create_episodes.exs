defmodule Radiator.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add :title, :string
      add :subtitle, :string
      add :description, :string
      add :content, :string
      add :image, :string
      add :duration, :string
      add :guid, :string
      add :number, :integer
      add :published_at, :utc_datetime
      add :podcast_id, references(:podcasts, on_delete: :delete_all)

      timestamps()
    end

    create index(:episodes, [:podcast_id])
  end
end
