defmodule Radiator.Repo.Migrations.AddPermTables do
  use Ecto.Migration

  def up do
    create table(:networks_perm, primary_key: false) do
      add :user_id, references("auth_users", on_delete: :delete_all), primary_key: true
      add :subject_id, references("networks", on_delete: :delete_all), primary_key: true
      add :permission, :string, size: 16, null: false

      timestamps()
    end

    create table(:podcasts_perm, primary_key: false) do
      add :user_id, references("auth_users", on_delete: :delete_all), primary_key: true
      add :subject_id, references("podcasts", on_delete: :delete_all), primary_key: true
      add :permission, :string, size: 16, null: false

      timestamps()
    end

    create table(:episodes_perm, primary_key: false) do
      add :user_id, references("auth_users", on_delete: :delete_all), primary_key: true
      add :subject_id, references("episodes", on_delete: :delete_all), primary_key: true
      add :permission, :string, size: 16, null: false

      timestamps()
    end

    create table(:audios_perm, primary_key: false) do
      add :user_id, references("auth_users", on_delete: :delete_all), primary_key: true
      add :subject_id, references("audios", on_delete: :delete_all), primary_key: true
      add :permission, :string, size: 16, null: false

      timestamps()
    end

    flush()
  end

  def down do
    drop table(:episodes_perm)
    drop table(:podcasts_perm)
    drop table(:networks_perm)
  end
end
