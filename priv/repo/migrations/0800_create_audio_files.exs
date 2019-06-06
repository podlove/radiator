defmodule Radiator.Repo.Migrations.CreateAudioFile do
  use Ecto.Migration

  def change do
    create table(:audio_files) do
      add :title, :string
      add :mime_type, :string
      add :byte_length, :integer
      add :file, :string

      add :audio_id, references(:audios, on_delete: :delete_all)

      timestamps()
    end
  end
end
