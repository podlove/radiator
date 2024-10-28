defmodule Radiator.Repo.Migrations.AddDataToUrls do
  use Ecto.Migration

  def change do
    alter table(:urls) do
      add :meta_data, :map, null: false, default: %{}
    end
  end
end
