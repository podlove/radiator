defmodule Radiator.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:auth_users) do
      add :name, :string
      add :email, :string
      add :display_name, :string
      add :password_hash, :binary
      add :status, :string, size: 40

      timestamps()
    end

    create unique_index(:auth_users, [:email])
    create unique_index(:auth_users, [:name])

    # advance the users id by a random amount, but at least 10 to ensure the first 10 ids are free for special users if needed
    # current plan is to make the id 1 a special public user
    execute(
      "select setval('auth_users_id_seq', nextval('auth_users_id_seq') + #{
        :rand.uniform(999) + 10
      })",
      ""
    )
  end
end
