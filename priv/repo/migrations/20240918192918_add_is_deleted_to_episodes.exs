defmodule Radiator.Repo.Migrations.AddIsDeletedToEpisodes do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add :is_deleted, :boolean, default: false
      add :deleted_at, :utc_datetime
    end
  end
end
