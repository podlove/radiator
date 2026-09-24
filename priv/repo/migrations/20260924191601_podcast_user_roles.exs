defmodule Radiator.Repo.Migrations.PodcastUserRoles do
  @moduledoc """
  Moves podcast ownership from `podcasts.user_id` to the `podcast_user_roles`
  join table. Every existing podcast's user becomes its owner.

  Generated with `mix ash_postgres.generate_migrations`, backfill added by hand.
  """

  use Ecto.Migration

  def up do
    create table(:podcast_user_roles, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :role, :text, null: false, default: "owner"

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :podcast_id,
          references(:podcasts,
            column: :id,
            name: "podcast_user_roles_podcast_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false

      add :user_id,
          references(:users,
            column: :id,
            name: "podcast_user_roles_user_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false
    end

    create unique_index(:podcast_user_roles, [:podcast_id, :user_id],
             name: "podcast_user_roles_unique_user_per_podcast_index"
           )

    create index(:podcast_user_roles, [:podcast_id])

    create index(:podcast_user_roles, [:user_id])

    execute("""
    INSERT INTO podcast_user_roles (podcast_id, user_id, role)
    SELECT id, user_id, 'owner' FROM podcasts WHERE user_id IS NOT NULL
    """)

    alter table(:podcasts) do
      remove :user_id
    end
  end

  def down do
    alter table(:podcasts) do
      add :user_id,
          references(:users,
            column: :id,
            name: "podcasts_user_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    # The owner who has been one the longest gets the podcast back.
    execute("""
    UPDATE podcasts p SET user_id = (
      SELECT r.user_id FROM podcast_user_roles r
      WHERE r.podcast_id = p.id AND r.role = 'owner'
      ORDER BY r.inserted_at ASC LIMIT 1
    )
    """)

    execute("ALTER TABLE podcasts ALTER COLUMN user_id SET NOT NULL")

    drop_if_exists index(:podcast_user_roles, [:user_id])

    drop_if_exists index(:podcast_user_roles, [:podcast_id])

    drop constraint(:podcast_user_roles, "podcast_user_roles_user_id_fkey")

    drop constraint(:podcast_user_roles, "podcast_user_roles_podcast_id_fkey")

    drop_if_exists unique_index(:podcast_user_roles, [:podcast_id, :user_id],
                     name: "podcast_user_roles_unique_user_per_podcast_index"
                   )

    drop table(:podcast_user_roles)
  end
end
