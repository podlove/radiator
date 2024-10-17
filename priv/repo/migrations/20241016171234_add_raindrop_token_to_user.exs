defmodule Radiator.Repo.Migrations.AddRaindropTokenToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :raindrop_token, :string
    end
  end
end
