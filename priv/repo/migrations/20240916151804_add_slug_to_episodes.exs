defmodule Radiator.Repo.Migrations.AddSlugToEpisodes do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add :slug, :string
    end
  end
end
