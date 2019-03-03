defmodule Radiator.GuidTest do
  use Radiator.DataCase

  alias Radiator.Directory
  alias Radiator.Directory.Episode

  import Radiator.Factory

  describe "episodes" do
    test "generate a guid on create" do
      podcast = insert(:podcast, %{})
      {:ok, episode} = Directory.create_episode(podcast, %{title: "foo"})

      assert is_binary(episode.guid)
      assert String.length(episode.guid) > 0
    end

    test "generate no guid on create if it is provided" do
      podcast = insert(:podcast, %{})
      {:ok, episode} = Directory.create_episode(podcast, %{title: "foo", guid: "provided"})

      assert episode.guid == "provided"
    end

    test "regenerates guid only on demand" do
      podcast = insert(:podcast, %{})

      {:ok, episode = %Episode{guid: original_guid}} =
        Directory.create_episode(podcast, %{title: "foo"})

      {:ok, episode} = Directory.update_episode(episode, %{title: "bar"})

      # unchanged after update
      assert episode.guid == original_guid

      {:ok, episode} = Directory.regenerate_episode_guid(episode)

      # changed after regenerate
      assert episode.guid != original_guid
    end
  end
end
