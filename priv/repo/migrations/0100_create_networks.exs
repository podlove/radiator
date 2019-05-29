defmodule Radiator.Repo.Migrations.CreateNetworks do
  use Ecto.Migration

  def change do
    create table(:networks) do
      add :title, :text
      add :image, :text
      add :slug, :string

      timestamps()
    end

    create unique_index(:networks, [:slug])
  end
end
