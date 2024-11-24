defmodule Radiator.Outline.NodeTest do
  @moduledoc false

  use Radiator.DataCase

  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepository
  alias Radiator.PodcastFixtures

  describe "insert_changeset/2" do
    test "put uuid if none exists" do
      episode = PodcastFixtures.episode_fixture()
      uuid = Ecto.UUID.generate()

      node1 =
        %Node{uuid: uuid, episode_id: episode.id}
        |> Node.insert_changeset(%{content: "some content"})
        |> Ecto.Changeset.apply_changes()

      assert node1.uuid == uuid

      node2 =
        %Node{episode_id: episode.id}
        |> Node.insert_changeset(%{content: "some other content"})
        |> Ecto.Changeset.apply_changes()

      refute node2.uuid == nil
    end

    test "accepts a UUID" do
      episode = PodcastFixtures.episode_fixture()

      uuid = Ecto.UUID.generate()

      attributes = %{
        "uuid" => uuid,
        "episode_id" => episode.id,
        "show_id" => episode.show_id,
        "content" => "Node Content"
      }

      assert {:ok, %Node{uuid: ^uuid}} = NodeRepository.create_node(attributes)
    end

    test "generates a UUID when none is provided" do
      episode = PodcastFixtures.episode_fixture()

      attributes = %{
        "episode_id" => episode.id,
        "show_id" => episode.show_id,
        "content" => "Node Content"
      }

      assert {:ok, %Node{uuid: uuid}} = NodeRepository.create_node(attributes)
      assert {:ok, _} = Ecto.UUID.cast(uuid)
    end

    test "validates the UUID" do
      episode = PodcastFixtures.episode_fixture()

      attributes = %{
        "uuid" => "not-a-uuid",
        "episode_id" => episode.id,
        "show_id" => episode.show_id,
        "content" => "Node Content"
      }

      assert {:error, changeset} = NodeRepository.create_node(attributes)
      assert [uuid: {"has invalid format", _}] = changeset.errors
    end
  end
end
