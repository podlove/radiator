defmodule Radiator.Repo.Migrations.CreateContributionRoles do
  use Ecto.Migration

  def change do
    create table(:contribution_roles) do
      add :title, :text

      timestamps()
    end
  end
end
