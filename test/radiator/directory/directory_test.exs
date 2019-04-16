defmodule Radiator.DirectoryTest do
  use Radiator.DataCase

  alias Radiator.Directory
  alias Directory.Editor

  import Radiator.Factory

  describe "podcasts" do
    alias Radiator.Directory.Podcast

    test "list_podcasts/0 returns all podcasts" do
      podcast = insert(:podcast)
      assert Directory.list_podcasts() == [podcast]
    end

    test "get_podcast!/1 returns the podcast with given id" do
      podcast = insert(:podcast)
      assert Directory.get_podcast!(podcast.id) == podcast
    end

    test "create_podcast/1 with valid data creates a podcast" do
      network = insert(:network)

      assert {:ok, %Podcast{} = podcast} =
               Directory.Editor.Manager.create_podcast(network, %{title: "some title"})

      assert podcast.title == "some title"
    end

    test "create_podcast/1 with invalid data returns error changeset" do
      network = insert(:network)
      assert {:error, %Ecto.Changeset{}} = Editor.Manager.create_podcast(network, %{title: nil})
    end

    test "update_podcast/2 with valid data updates the podcast" do
      podcast = insert(:podcast)

      assert {:ok, %Podcast{} = podcast} =
               Editor.Manager.update_podcast(podcast, %{subtitle: "some updated subtitle"})

      assert podcast.subtitle == "some updated subtitle"
    end

    test "update_podcast/2 with invalid data returns error changeset" do
      podcast = insert(:podcast)

      assert {:error, %Ecto.Changeset{}} = Editor.Manager.update_podcast(podcast, %{title: nil})

      assert podcast == Directory.get_podcast!(podcast.id)
    end

    test "delete_podcast/1 deletes the podcast" do
      podcast = insert(:podcast)
      assert {:ok, %Podcast{}} = Editor.Manager.delete_podcast(podcast)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_podcast!(podcast.id) end
    end

    test "change_podcast/1 returns a podcast changeset" do
      podcast = insert(:podcast)
      assert %Ecto.Changeset{} = Editor.Manager.change_podcast(podcast)
    end
  end

  describe "episodes" do
    alias Radiator.Directory.Episode

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    test "list_episodes/0 returns all episodes" do
      episode = insert(:episode)
      assert Directory.list_episodes() |> Repo.preload(:podcast) == [episode]
    end

    test "get_episode!/1 returns the episode with given id" do
      episode = insert(:episode)
      assert Directory.get_episode!(episode.id) |> Repo.preload(:podcast) == episode
    end

    test "create_episode/1 with valid data creates a episode" do
      assert {:ok, %Episode{} = episode} =
               Editor.Manager.create_episode(insert(:podcast), @valid_attrs)

      assert episode.title == "some title"
    end

    test "create_episode/1 with invalid data returns error changeset" do
      podcast = insert(:podcast)

      assert {:error, %Ecto.Changeset{}} = Editor.Manager.create_episode(podcast, @invalid_attrs)
    end

    test "update_episode/2 with valid data updates the episode" do
      episode = insert(:episode)
      assert {:ok, %Episode{} = episode} = Editor.Manager.update_episode(episode, @update_attrs)
      assert episode.title == "some updated title"
    end

    test "update_episode/2 with invalid data returns error changeset" do
      episode = insert(:episode)
      assert {:error, %Ecto.Changeset{}} = Editor.Manager.update_episode(episode, @invalid_attrs)
      assert episode == Directory.get_episode!(episode.id) |> Repo.preload(:podcast)
    end

    test "delete_episode/1 deletes the episode" do
      episode = insert(:episode)
      assert {:ok, %Episode{}} = Editor.Manager.delete_episode(episode)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_episode!(episode.id) end
    end

    test "change_episode/1 returns a episode changeset" do
      episode = insert(:episode)
      assert %Ecto.Changeset{} = Editor.Manager.change_episode(episode)
    end
  end

  describe "networks" do
    alias Radiator.Directory.Network

    @valid_attrs %{image: "some image", title: "some title"}
    @update_attrs %{image: "some updated image", title: "some updated title"}
    @invalid_attrs %{image: nil, title: nil}

    def network_fixture(attrs \\ %{}) do
      testuser = Radiator.TestEntries.user()

      {:ok, %{network: network}} =
        Editor.Owner.create_network(testuser, Enum.into(attrs, @valid_attrs))

      network
    end

    test "list_networks/0 returns all networks" do
      network = network_fixture()
      assert Directory.list_networks() == [network]
    end

    test "get_network!/1 returns the network with given id" do
      network = network_fixture()
      assert Directory.get_network!(network.id) == network
    end

    test "create_network/1 with valid data creates a network" do
      testuser = Radiator.TestEntries.user()

      assert {:ok, %{network: %Network{} = network}} =
               Editor.Owner.create_network(testuser, @valid_attrs)

      assert network.image == "some image"
      assert network.title == "some title"
    end

    test "create_network/1 with invalid data returns error changeset" do
      testuser = Radiator.TestEntries.user()

      assert {:error, :network, %Ecto.Changeset{}, _} =
               Editor.Owner.create_network(testuser, @invalid_attrs)
    end

    test "update_network/2 with valid data updates the network" do
      network = network_fixture()
      assert {:ok, %Network{} = network} = Editor.Owner.update_network(network, @update_attrs)
      assert network.image == "some updated image"
      assert network.title == "some updated title"
    end

    test "update_network/2 with invalid data returns error changeset" do
      network = network_fixture()
      assert {:error, %Ecto.Changeset{}} = Editor.Owner.update_network(network, @invalid_attrs)
      assert network == Directory.get_network!(network.id)
    end

    test "delete_network/1 deletes the network" do
      network = network_fixture()
      assert {:ok, %Network{}} = Editor.Owner.delete_network(network)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_network!(network.id) end
    end
  end
end
