defmodule Radiator.Repo.Migrations.CreatePodcasts do
  use Ecto.Migration

  def change do
    create table(:podcasts) do
      add :title, :text
      add :subtitle, :text
      add :description, :text
      add :image, :string
      add :author, :string
      add :owner_name, :string
      add :owner_email, :string
      add :language, :string
      add :published_at, :utc_datetime
      add :last_built_at, :utc_datetime
      add :slug, :string
      add :short_id, :string
      add :main_color, :string, size: 7
      add :is_using_short_id, :boolean

      add :network_id, references(:networks, on_delete: :delete_all)

      timestamps()
    end

    create index(:podcasts, ["lower(slug)"], unique: true)
    create index(:podcasts, ["lower(short_id)"])
  end
end
