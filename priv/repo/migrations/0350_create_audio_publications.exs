defmodule Radiator.Repo.Migrations.CreateAudioPublications do
  use Ecto.Migration

  def change do
    create table(:audio_publications) do
      add :publish_state, :string
      add :published_at, :utc_datetime

      add :network_id, references(:networks, on_delete: :delete_all)
      add :audio_id, references(:audios, on_delete: :nilify_all)

      timestamps()
    end
  end
end
