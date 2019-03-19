defmodule Radiator.Auth.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :display_name, :string
      add :pass, :string

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:name])
  end
end
