defmodule Radiator.Repo.Migrations.CreateAudio do
  use Ecto.Migration

  def change do
    create table(:audios) do
      add :title, :string
      add :mime_type, :string
      add :byte_length, :integer
      add :file, :string

      timestamps()
    end
  end
end
