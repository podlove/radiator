defmodule Radiator.Repo.Migrations.FixSingleDeploy do
  use Ecto.Migration

  # temporary migration to be migrated, rolled back and then removed from the repo again with these lines in the shell of the container

  # ./prod/rel/radiator/bin/radiator eval "Radiator.Release.migrate()"

  # ./prod/rel/radiator/bin/radiator eval "Application.load(:radiator); Application.fetch_env!(:radiator, :ecto_repos); Radiator.Release.rollback(Radiator.Repo, 1301)"

  def up do
    # from 0200
    alter table(:podcasts) do
      add :publish_state, :string
    end

    # from 1000
    alter table(:downloads) do
      add :referer, :text
    end

    create unique_index(
             :downloads,
             [:file_id, :request_id, "(accessed_at::date)"],
             name: :downloads_daily_unique_request_index
           )

    # from 1050
    create table(:reports, primary_key: false) do
      add :uid, :string, primary_key: true, null: false

      add :subject_type, :string
      add :subject, :integer
      add :time_type, :string
      add :time, :string

      add :downloads, :integer
      add :listeners, :integer
      add :location, :map
      add :user_agents, :map

      timestamps()
    end
  end

  def down do
  end
end
