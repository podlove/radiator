defmodule Radiator.Repo.Migrations.UpdatePodcastTableTextFields do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      modify :title, :text
      modify :subtitle, :text
      modify :description, :text
    end
  end
end
