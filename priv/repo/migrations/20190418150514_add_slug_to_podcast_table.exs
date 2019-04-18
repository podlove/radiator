defmodule Radiator.Repo.Migrations.AddSlugToPodcastTable do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :slug, :string
    end

    create unique_index(:podcasts, [:slug])
  end
end
