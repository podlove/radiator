defmodule Radiator.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :real_name, :text
      add :display_name, :text
      add :nick_name, :text
      add :gender, :text
      add :email, :text
      add :avatar, :string

      add :user_id, references(:auth_users, on_delete: :nothing)

      timestamps()
    end
  end
end
