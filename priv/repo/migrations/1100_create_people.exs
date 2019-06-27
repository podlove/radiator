defmodule Radiator.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :text
      add :display_name, :text
      add :nick, :text
      add :email, :text
      add :avatar, :string
      add :uri, :text

      add :user_id, references(:auth_users, on_delete: :nothing)
      add :network_id, references(:networks, on_delete: :nothing)

      timestamps()
    end
  end
end
