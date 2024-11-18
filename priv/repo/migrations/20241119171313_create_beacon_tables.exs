defmodule Radiator.Repo.Migrations.CreateBeaconTables do
  use Ecto.Migration

  def up, do: Beacon.Migration.up()
  def down, do: Beacon.Migration.down()
end
