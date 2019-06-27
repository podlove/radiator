defmodule Radiator.Repo.Migrations.CreateAudioContributions do
  use Ecto.Migration

  def change do
    create table(:audio_contributions) do
      add :position, :float
      add :person_id, references(:people, on_delete: :delete_all)
      add :audio_id, references(:audios, on_delete: :delete_all)
      add :role_id, references(:contribution_roles, on_delete: :delete_all)

      timestamps()
    end

    create table(:podcast_contributions) do
      add :position, :float
      add :person_id, references(:people, on_delete: :delete_all)
      add :podcast_id, references(:podcasts, on_delete: :delete_all)
      add :role_id, references(:contribution_roles, on_delete: :delete_all)

      timestamps()
    end
  end
end
