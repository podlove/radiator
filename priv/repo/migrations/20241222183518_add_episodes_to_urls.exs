defmodule Radiator.Repo.Migrations.AddEpisodesToUrls do
  use Ecto.Migration

  def change do
    alter table(:urls) do
      add :episode_id, references(:episodes, on_delete: :nothing)
    end
  end
end
