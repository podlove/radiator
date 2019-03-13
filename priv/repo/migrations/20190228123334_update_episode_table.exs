defmodule Radiator.Repo.Migrations.UpdateEpisodeTable do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      modify :content, :text
      modify :description, :text
    end
  end
end
