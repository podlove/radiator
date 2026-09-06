defmodule Radiator.Repo.Migrations.DropExisting do
  @moduledoc """
  Drop all existing tables and start fresh
  """

  use Ecto.Migration

  def up do
    drop_if_exists table(:transcripts)
    drop_if_exists table(:tracks)
    drop_if_exists table(:chapters)
    drop_if_exists table(:episode_scheduling)
    drop_if_exists table(:episode_participants)
    drop_if_exists table(:episodes)
    drop_if_exists table(:shows)
    drop_if_exists table(:licenses)
    drop_if_exists table(:roles)
    drop_if_exists table(:users)
    drop_if_exists table(:people)
    drop_if_exists table(:tokens)
  end
end
