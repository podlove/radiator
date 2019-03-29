defmodule Radiator.Repo.Migrations.CreateChapters do
  use Ecto.Migration

  def change do
    create table(:chapters) do
      add :time, :integer
      add :title, :text
      add :link_url, :text
      add :image_url, :text

      add :episode_id, references(:episodes, on_delete: :nothing)
    end
  end
end
