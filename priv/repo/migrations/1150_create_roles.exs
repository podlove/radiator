defmodule Radiator.Repo.Migrations.CreateContributionRoles do
  use Ecto.Migration
  alias Radiator.Repo
  alias Radiator.Contribution.Role

  def up do
    create table(:contribution_roles) do
      add :title, :text
      add :is_public, :boolean

      timestamps()
    end

    flush()

    Repo.insert!(%Role{title: "On Air", public?: true})
    Repo.insert!(%Role{title: "Support", public?: true})
    Repo.insert!(%Role{title: "Internal Support", public?: false})
  end

  def down do
    drop table(:contribution_roles)
  end
end
