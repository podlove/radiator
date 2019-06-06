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

      add :network_id, references(:networks, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:podcasts, [:slug])
  end
end
