defmodule Radiator.Repo.Migrations.CreateWebServices do
  use Ecto.Migration

  def change do
    create table(:web_services) do
      add :service_name, :string
      add :data, :map
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:web_services, [:user_id])
    create unique_index(:web_services, [:user_id, :service_name])
  end
end
