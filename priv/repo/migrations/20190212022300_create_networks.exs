defmodule Radiator.Repo.Migrations.CreateNetworks do
  use Ecto.Migration

  def change do
    create table(:networks) do
      add :title, :text
      add :image, :text

      timestamps()
    end
  end
end
