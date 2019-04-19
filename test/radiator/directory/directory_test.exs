defmodule Radiator.DirectoryTest do
  use Radiator.DataCase

  alias Radiator.Directory

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
               Directory.create_podcast(network, %{title: "some title"})

      assert podcast.title == "some title"
    end

    test "create_podcast/1 with invalid data returns error changeset" do
      network = insert(:network)
      assert {:error, %Ecto.Changeset{}} = Directory.create_podcast(network, %{title: nil})
    end

    test "update_podcast/2 with valid data updates the podcast" do
      podcast = insert(:podcast)

      assert {:ok, %Podcast{} = podcast} =
               Directory.update_podcast(podcast, %{subtitle: "some updated subtitle"})

      assert podcast.subtitle == "some updated subtitle"
    end

    test "update_podcast/2 with invalid data returns error changeset" do
      podcast = insert(:podcast)
      assert {:error, %Ecto.Changeset{}} = Directory.update_podcast(podcast, %{title: nil})
      assert podcast == Directory.get_podcast!(podcast.id)
    end

    test "delete_podcast/1 deletes the podcast" do
      podcast = insert(:podcast)
      assert {:ok, %Podcast{}} = Directory.delete_podcast(podcast)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_podcast!(podcast.id) end
    end

    test "change_podcast/1 returns a podcast changeset" do
      podcast = insert(:podcast)
      assert %Ecto.Changeset{} = Directory.change_podcast(podcast)
    end

    test "publish_podcast/1 sets a podcasts published_at date" do
      podcast = insert(:podcast, published_at: nil)

      assert {:ok, %Podcast{} = published_podcast} = Directory.publish_podcast(podcast.id)
      assert published_podcast.published_at != nil
      assert :gt == DateTime.compare(DateTime.utc_now(), published_podcast.published_at)
    end

    test "publish_podcast/1 returns error for non existing podcasts" do
      podcast = insert(:podcast)
      {:ok, _deleted_podcast} = Directory.delete_podcast(podcast)

      assert {:error, :not_found} = Directory.publish_podcast(podcast.id)
    end

    test "depublish_podcast/1 removes a podcasts published_at date" do
      podcast = insert(:podcast, published_at: DateTime.utc_now())

      assert {:ok, %Podcast{published_at: nil}} = Directory.depublish_podcast(podcast.id)
    end

    test "depublish_podcast/1 returns error for non existing podcasts" do
      podcast = insert(:podcast)
      {:ok, _deleted_podcast} = Directory.delete_podcast(podcast)

      assert {:error, :not_found} = Directory.depublish_podcast(podcast.id)
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
               Directory.create_episode(insert(:podcast), @valid_attrs)

      assert episode.title == "some title"
    end

    test "create_episode/1 with invalid data returns error changeset" do
      podcast = insert(:podcast)
      assert {:error, %Ecto.Changeset{}} = Directory.create_episode(podcast, @invalid_attrs)
    end

    test "update_episode/2 with valid data updates the episode" do
      episode = insert(:episode)
      assert {:ok, %Episode{} = episode} = Directory.update_episode(episode, @update_attrs)
      assert episode.title == "some updated title"
    end

    test "update_episode/2 with invalid data returns error changeset" do
      episode = insert(:episode)
      assert {:error, %Ecto.Changeset{}} = Directory.update_episode(episode, @invalid_attrs)
      assert episode == Directory.get_episode!(episode.id) |> Repo.preload(:podcast)
    end

    test "delete_episode/1 deletes the episode" do
      episode = insert(:episode)
      assert {:ok, %Episode{}} = Directory.delete_episode(episode)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_episode!(episode.id) end
    end

    test "change_episode/1 returns a episode changeset" do
      episode = insert(:episode)
      assert %Ecto.Changeset{} = Directory.change_episode(episode)
    end
  end

  describe "networks" do
    alias Radiator.Directory.Network

    @valid_attrs %{image: "some image", title: "some title"}
    @update_attrs %{image: "some updated image", title: "some updated title"}
    @invalid_attrs %{image: nil, title: nil}

    def network_fixture(attrs \\ %{}) do
      {:ok, network} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Directory.create_network()

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
      assert {:ok, %Network{} = network} = Directory.create_network(@valid_attrs)
      assert network.image == "some image"
      assert network.title == "some title"
    end

    test "create_network/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Directory.create_network(@invalid_attrs)
    end

    test "update_network/2 with valid data updates the network" do
      network = network_fixture()
      assert {:ok, %Network{} = network} = Directory.update_network(network, @update_attrs)
      assert network.image == "some updated image"
      assert network.title == "some updated title"
    end

    test "update_network/2 with invalid data returns error changeset" do
      network = network_fixture()
      assert {:error, %Ecto.Changeset{}} = Directory.update_network(network, @invalid_attrs)
      assert network == Directory.get_network!(network.id)
    end

    test "delete_network/1 deletes the network" do
      network = network_fixture()
      assert {:ok, %Network{}} = Directory.delete_network(network)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_network!(network.id) end
    end

    test "change_network/1 returns a network changeset" do
      network = network_fixture()
      assert %Ecto.Changeset{} = Directory.change_network(network)
    end
  end
end
