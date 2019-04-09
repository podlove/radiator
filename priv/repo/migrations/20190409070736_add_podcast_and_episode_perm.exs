defmodule Radiator.Repo.Migrations.AddPodcastAndEpisodePerm do
  use Ecto.Migration

  def up do
    create table(:podcasts_perm) do
      add :user_id, references("auth_users", on_delete: :delete_all)
      add :podcast_id, references("podcasts", on_delete: :delete_all)
      add :permission, :string, size: 16, null: false

      timestamps()
    end

    create unique_index(:podcasts_perm, [:user_id, :podcast_id, :permission])

    flush()

    Radiator.Repo.insert(Radiator.Auth.User.reserved_user(:public))
  end

  def down do
    drop table(:podcasts_perm)

    Radiator.Repo.delete(Radiator.Auth.User.reserved_user(:public))
  end
end
