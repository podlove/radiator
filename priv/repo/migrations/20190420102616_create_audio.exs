defmodule Radiator.Repo.Migrations.CreateAudioFile do
  use Ecto.Migration

  def change do
    create table(:audio_files) do
      add :title, :string
      add :mime_type, :string
      add :byte_length, :integer
      add :file, :string

      timestamps()
    end
  end
end
