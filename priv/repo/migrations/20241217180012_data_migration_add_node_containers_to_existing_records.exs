defmodule Radiator.Repo.Migrations.AddNodeContainersToExistingRecords do
  use Ecto.Migration

  import Ecto.Query, warn: false
  alias Radiator.Repo
  alias Radiator.Outline.{Node, NodeContainer}
  alias Radiator.Podcast.{Episode, Show}

  def up do
    # Disable automatic timestamps for this migration
    Application.put_env(:radiator, :disable_timestamps, true)

    # Add node containers to existing shows
    Repo.all(Show)
    |> Enum.each(fn show ->
      # Create containers
      {:ok, inbox} = %NodeContainer{} |> Repo.insert()
      {:ok, outline} = %NodeContainer{} |> Repo.insert()

      # Update show with containers
      show
      |> Ecto.Changeset.change(%{
        inbox_node_container_id: inbox.id,
        outline_node_container_id: outline.id
      })
      |> Repo.update!()

      # Update all nodes belonging to this show
      from(n in Node, where: n.show_id == ^show.id)
      |> Repo.update_all(set: [outline_node_container_id: outline.id])
    end)

    # Add node containers to existing episodes
    Repo.all(Episode)
    |> Enum.each(fn episode ->
      # Create containers
      {:ok, inbox} = %NodeContainer{} |> Repo.insert()
      {:ok, outline} = %NodeContainer{} |> Repo.insert()

      # Update episode with containers
      episode
      |> Ecto.Changeset.change(%{
        inbox_node_container_id: inbox.id,
        outline_node_container_id: outline.id
      })
      |> Repo.update!()

      # Update all nodes belonging to this episode
      from(n in Node, where: n.episode_id == ^episode.id)
      |> Repo.update_all(set: [outline_node_container_id: outline.id])
    end)

    # Re-enable automatic timestamps
    Application.delete_env(:radiator, :disable_timestamps)
  end

  def down do
    # In down migration, we'll remove the container associations but keep the containers
    # to prevent data loss

    # Remove container associations from shows
    from(s in Show)
    |> Repo.update_all(
      set: [
        inbox_node_container_id: nil,
        outline_node_container_id: nil
      ]
    )

    # Remove container associations from episodes
    from(e in Episode)
    |> Repo.update_all(
      set: [
        inbox_node_container_id: nil,
        outline_node_container_id: nil
      ]
    )

    # Remove container associations from nodes
    from(n in Node)
    |> Repo.update_all(set: [outline_node_container_id: nil])
  end
end
