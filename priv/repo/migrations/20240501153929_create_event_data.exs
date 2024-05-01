defmodule Radiator.Repo.Migrations.CreateEventData do
  use Ecto.Migration

  def change do
    create table(:event_data, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :event_type, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :data, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:event_data, [:user_id])
  end
end
