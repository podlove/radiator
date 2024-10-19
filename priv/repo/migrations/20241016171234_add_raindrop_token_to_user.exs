defmodule Radiator.Repo.Migrations.AddRaindropTokenToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :raindrop_access_token, :string
      add :raindrop_refresh_token, :string
    end
  end
end