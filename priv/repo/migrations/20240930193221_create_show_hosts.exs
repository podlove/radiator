defmodule Radiator.Repo.Migrations.CreateShowHosts do
  use Ecto.Migration

  def change do
    create table(:show_hosts) do
      add :show_id, references(:shows, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:show_hosts, [:show_id])
    create index(:show_hosts, [:user_id])
  end
end
