defmodule Radiator.Repo.Migrations.ChangePodcastsAddHostname do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :hostname, :string
    end
  end
end
