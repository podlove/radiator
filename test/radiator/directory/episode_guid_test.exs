defmodule Radiator.GuidTest do
  use Radiator.DataCase

  alias Radiator.Directory
  alias Radiator.Directory.Episode
  alias Radiator.Directory.Editor

  import Radiator.Factory

  describe "episodes" do
    test "generate a guid on create" do
      podcast = insert(:podcast, %{}) |> publish()
      {:ok, episode} = Editor.Manager.create_episode(podcast, %{title: "foo"})

      assert is_binary(episode.guid)
      assert String.length(episode.guid) > 0
    end

    test "generate no guid on create if it is provided" do
      podcast = insert(:podcast, %{}) |> publish()

      {:ok, episode} =
        Directory.Editor.Manager.create_episode(podcast, %{title: "foo", guid: "provided"})

      assert episode.guid == "provided"
    end

    test "regenerates guid only on demand" do
      podcast = insert(:podcast, %{}) |> publish()

      {:ok, episode = %Episode{guid: original_guid}} =
        Editor.Manager.create_episode(podcast, %{title: "foo"})

      {:ok, episode} = Editor.Manager.update_episode(episode, %{title: "bar"})

      # unchanged after update
      assert episode.guid == original_guid

      {:ok, episode} = Editor.Manager.regenerate_episode_guid(episode)

      # changed after regenerate
      assert episode.guid != original_guid
    end
  end
end
