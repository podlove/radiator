defmodule Radiator.Repo.Migrations.CreateAudios do
  use Ecto.Migration

  def change do
    create table(:audios) do
      add :title, :text
      add :duration, :integer
      add :image, :text

      timestamps()
    end
  end
end
