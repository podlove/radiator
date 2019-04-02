defmodule Radiator.Repo.Migrations.CreateChapters do
  use Ecto.Migration

  def change do
    create table(:chapters) do
      add :time, :integer
      add :title, :text
      add :url, :text
      add :image, :text

      add :episode_id, references(:episodes, on_delete: :nothing)
    end
  end
end
