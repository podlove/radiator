defmodule Radiator.Repo.Migrations.CreateAudio do
  use Ecto.Migration

  def change do
    create table(:audio) do
      add :title, :string
      add :file, :string

      timestamps()
    end

  end
end
