defmodule Radiator.Repo.Migrations.CreateChapters do
  use Ecto.Migration

  def change do
    create table(:chapters) do
      add :start, :integer
      add :title, :text
      add :link, :text
      add :image, :text

      add :episode_id, references(:episodes, on_delete: :nothing)
    end
  end
end
