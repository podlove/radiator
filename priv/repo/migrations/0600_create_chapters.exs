defmodule Radiator.Repo.Migrations.CreateChapters do
  use Ecto.Migration

  def change do
    create table(:chapters) do
      add :start, :integer
      add :title, :text
      add :link, :text
      add :image, :string

      add :audio_id, references(:audios, on_delete: :delete_all)
    end
  end
end
