defmodule Radiator.Repo.Migrations.AddNumberToEpisodes do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add :number, :integer
    end
  end
end
