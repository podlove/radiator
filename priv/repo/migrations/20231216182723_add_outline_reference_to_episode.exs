defmodule Radiator.Repo.Migrations.AddOutlineReferenceToEpisode do
  use Ecto.Migration

  def change do
    alter table(:outline_nodes) do
      add :episode_id, references(:episodes, on_delete: :nothing)
    end
  end
end
