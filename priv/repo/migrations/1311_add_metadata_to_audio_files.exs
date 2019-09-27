defmodule Radiator.Repo.Migrations.AddMetadataToAudioFiles do
  use Ecto.Migration

  def change do
    alter table(:audio_files) do
      add :audio_format, :string
      add :duration, :integer
    end
  end
end
