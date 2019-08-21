defmodule Radiator.Repo.Migrations.CreateUserProfiles do
  use Ecto.Migration

  def change do
    create table(:user_profiles) do
      add :display_name, :text
      add :image, :text

      add :user_id, references(:auth_users, on_delete: :nothing)

      timestamps()
    end
  end
end
