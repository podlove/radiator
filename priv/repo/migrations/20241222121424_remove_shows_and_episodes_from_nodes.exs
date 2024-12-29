defmodule Radiator.Repo.Migrations.RemoveShowsAndEpisodesFromNodes do
  use Ecto.Migration

  def change do
    alter table(:outline_nodes) do
      remove :episode_id, references(:episodes, on_delete: :nothing)
      remove :show_id, references(:shows, on_delete: :nothing)
    end
  end
end
