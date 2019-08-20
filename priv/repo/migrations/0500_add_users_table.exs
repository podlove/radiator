defmodule Radiator.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:auth_users) do
      add :name, :text
      add :email, :text
      add :password_hash, :binary
      add :status, :string, null: false, size: 40

      timestamps()
    end

    create index(:auth_users, ["(lower(email))"], unique: true)
    create index(:auth_users, ["(lower(name))"], unique: true)

    # advance the users id by a random amount, but at least `User.max_reserved_user_id()`
    # so the first real user id will have a random id.
    execute(
      "select setval('auth_users_id_seq', nextval('auth_users_id_seq') + #{
        :rand.uniform(999) + Radiator.Auth.User.max_reserved_user_id()
      })",
      ""
    )
  end
end
