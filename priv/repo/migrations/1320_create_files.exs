defmodule Radiator.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :file, :text
      add :size, :integer
      add :name, :text
      add :mime_type, :string
      add :extension, :string

      add :network_id, references(:networks, on_delete: :delete_all)

      timestamps()
    end
  end
end
