defmodule Radiator.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add :guid, :text
      add :short_id, :string
      add :title, :text
      add :subtitle, :text
      add :summary, :text
      add :summary_html, :text
      add :summary_source, :text

      add :number, :integer

      add :publish_state, :string
      add :published_at, :utc_datetime

      add :slug, :string

      add :network_id, references(:networks, on_delete: :delete_all)
      add :podcast_id, references(:podcasts, on_delete: :delete_all)
      add :audio_id, references(:audios, on_delete: :nilify_all)

      timestamps()
    end

    create index(:episodes, [:guid])
    create index(:episodes, [:podcast_id])
    create index(:episodes, [:network_id])
    create index(:episodes, ["lower(short_id)"])
    create index(:episodes, ["lower(slug)", :podcast_id], unique: true)
  end
end
