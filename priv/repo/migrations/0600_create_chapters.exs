defmodule Radiator.Repo.Migrations.CreateChapters do
  use Ecto.Migration

  def change do
    create table(:chapters, primary_key: false) do
      add :audio_id, references(:audios, on_delete: :delete_all), primary_key: true

      add :start, :integer, primary_key: true
      add :title, :text
      add :link, :text
      add :image, :string
    end
  end
end
