defmodule Radiator.Repo.Migrations.CreateAttachmentTables do
  use Ecto.Migration

  def up do
    create table(:network_attachments, primary_key: false) do
      add :audio_id, references("audio_files", on_delete: :delete_all), primary_key: true
      add :subject_id, references("networks", on_delete: :delete_all), primary_key: true

      timestamps()
    end

    create table(:episode_attachments, primary_key: false) do
      add :audio_id, references("audio_files", on_delete: :delete_all), primary_key: true
      add :subject_id, references("episodes", on_delete: :delete_all), primary_key: true

      timestamps()
    end
  end

  def down do
    drop table(:episode_attachments)
    drop table(:network_attachments)
  end
end
