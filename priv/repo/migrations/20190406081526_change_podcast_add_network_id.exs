defmodule Radiator.Repo.Migrations.ChangePodcastAddNetworkId do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :network_id, references(:networks, on_delete: :nothing)
    end
  end
end
