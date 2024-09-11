defmodule Radiator.Repo.Migrations.AddPublishDateDateToEpisodes do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add :publish_date, :date
    end
  end
end
