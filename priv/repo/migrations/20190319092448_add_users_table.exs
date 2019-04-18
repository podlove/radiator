defmodule Radiator.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:auth_users) do
      add :name, :string
      add :email, :string
      add :display_name, :string
      add :avatar, :string
      add :password_hash, :binary
      add :status, :string, size: 40

      timestamps()
    end

    create unique_index(:auth_users, [:email])
    create unique_index(:auth_users, [:name])
  end
end
