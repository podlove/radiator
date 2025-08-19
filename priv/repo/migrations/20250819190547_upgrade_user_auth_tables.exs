defmodule Radiator.Repo.Migrations.UpgradeUserAuthTables do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :hashed_password, :string, null: true
    end

    alter table(:users_tokens) do
      add :authenticated_at, :utc_datetime
    end
  end
end
