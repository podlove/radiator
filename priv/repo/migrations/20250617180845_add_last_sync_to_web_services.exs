defmodule Radiator.Repo.Migrations.AddLastSyncToWebServices do
  use Ecto.Migration

  def change do
    alter table(:web_services) do
      add :last_sync, :utc_datetime
    end
  end
end
