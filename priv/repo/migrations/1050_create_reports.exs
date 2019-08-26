defmodule Radiator.Repo.Migrations.CreateReports do
  use Ecto.Migration

  def change do
    create table(:reports, primary_key: false) do
      add :uid, :string, primary_key: true, null: false

      add :subject_type, :string
      add :subject, :integer
      add :time_type, :string
      add :time, :string

      add :downloads, :integer
      add :listeners, :integer
      add :location, :map
      add :user_agents, :map

      timestamps()
    end
  end
end
