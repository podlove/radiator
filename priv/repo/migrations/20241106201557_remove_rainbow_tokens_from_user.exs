defmodule Radiator.Repo.Migrations.RemoveRainbowTokensFromUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :raindrop_access_token, :string
      remove :raindrop_refresh_token, :string
      remove :raindrop_expires_at, :utc_datetime
    end
  end
end
