defmodule Radiator.PodcastTest do
  use Radiator.DataCase

  import Radiator.PodcastFixtures

  alias Radiator.Podcast
  alias Radiator.Podcast.{Episode, Network, Show}

  describe "networks" do
    @invalid_attrs %{title: nil}

    test "list_networks/0 returns all networks" do
      network = network_fixture()
      assert Podcast.list_networks() == [network]
    end

    test "get_network!/1 returns the network with given id" do
      network = network_fixture()
      assert Podcast.get_network!(network.id) == network
    end

    test "create_network/1 with valid data creates a network" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %Network{} = network} = Podcast.create_network(valid_attrs)
      assert network.title == "some title"
    end

    test "create_network/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Podcast.create_network(@invalid_attrs)
    end

    test "update_network/2 with valid data updates the network" do
      network = network_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Network{} = network} = Podcast.update_network(network, update_attrs)
      assert network.title == "some updated title"
    end

    test "update_network/2 with invalid data returns error changeset" do
      network = network_fixture()
      assert {:error, %Ecto.Changeset{}} = Podcast.update_network(network, @invalid_attrs)
      assert network == Podcast.get_network!(network.id)
    end

    test "delete_network/1 deletes the network" do
      network = network_fixture()
      assert {:ok, %Network{}} = Podcast.delete_network(network)
      assert_raise Ecto.NoResultsError, fn -> Podcast.get_network!(network.id) end
    end

    test "change_network/1 returns a network changeset" do
      network = network_fixture()
      assert %Ecto.Changeset{} = Podcast.change_network(network)
    end
  end

  describe "shows" do
    @invalid_attrs %{title: nil, hostname: nil}

    test "list_shows/0 returns all shows" do
      show = show_fixture()
      assert Podcast.list_shows() == [show]
    end

    test "get_show!/1 returns the show with given id" do
      show = show_fixture()
      assert Podcast.get_show!(show.id) == show
    end

    test "create_show/1 with valid data creates a show" do
      network = network_fixture()
      valid_attrs = %{title: "some title", network_id: network.id}

      assert {:ok, %Show{} = show} = Podcast.create_show(valid_attrs)
      assert show.title == "some title"
      assert show.network_id == network.id
    end

    test "create_show/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Podcast.create_show(@invalid_attrs)
    end

    test "update_show/2 with valid data updates the show" do
      show = show_fixture()
      updated_network = network_fixture()
      update_attrs = %{title: "some updated title", network_id: updated_network.id}

      assert {:ok, %Show{} = show} = Podcast.update_show(show, update_attrs)
      assert show.title == "some updated title"
      assert show.network_id == updated_network.id
    end

    test "update_show/2 with invalid data returns error changeset" do
      show = show_fixture()
      assert {:error, %Ecto.Changeset{}} = Podcast.update_show(show, @invalid_attrs)
      assert show == Podcast.get_show!(show.id)
    end

    test "delete_show/1 deletes the show" do
      show = show_fixture()
      assert {:ok, %Show{}} = Podcast.delete_show(show)
      assert_raise Ecto.NoResultsError, fn -> Podcast.get_show!(show.id) end
    end

    test "change_show/1 returns a show changeset" do
      show = show_fixture()
      assert %Ecto.Changeset{} = Podcast.change_show(show)
    end
  end

  describe "episodes" do
    @invalid_attrs %{title: nil}

    test "list_episodes/0 returns all episodes" do
      episode = episode_fixture()
      assert Podcast.list_episodes() == [episode]
    end

    test "get_episode!/1 returns the episode with given id" do
      episode = episode_fixture()
      assert Podcast.get_episode!(episode.id) == episode
    end

    test "create_episode/1 with valid data creates a episode" do
      show = show_fixture()
      valid_attrs = %{title: "some title", show_id: show.id}

      assert {:ok, %Episode{} = episode} = Podcast.create_episode(valid_attrs)
      assert episode.title == "some title"
      assert episode.show_id == show.id
    end

    test "create_episode/1 sets for first episode number 1" do
      episode_attrs = %{title: "a new episode", show_id: show_fixture().id}

      {:ok, %Episode{} = episode} = Podcast.create_episode(episode_attrs)
      assert episode.number > 0
    end

    test "create_episode/1 finds the next highest number " do
      show = show_fixture()
      episode_fixture(show_id: show.id, number: 23)
      episode_attrs = %{title: "my new episode", show_id: show.id}

      {:ok, %Episode{} = episode} = Podcast.create_episode(episode_attrs)
      assert episode.number == 24
    end

    test "create_episode/1 can be set explict" do
      show = show_fixture()
      episode_fixture(show_id: show.id, number: 2)
      episode_attrs = %{title: "my new episode", number: 5, show_id: show.id}

      {:ok, %Episode{} = episode} = Podcast.create_episode(episode_attrs)
      assert episode.number == 5
    end

    test "create_episode/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Podcast.create_episode(@invalid_attrs)
    end

    test "update_episode/2 with valid data updates the episode" do
      episode = episode_fixture()
      updated_podcast = show_fixture()
      update_attrs = %{title: "some updated title", show_id: updated_podcast.id}

      assert {:ok, %Episode{} = episode} = Podcast.update_episode(episode, update_attrs)
      assert episode.title == "some updated title"
      assert episode.show_id == updated_podcast.id
    end

    test "update_episode/2 with invalid data returns error changeset" do
      episode = episode_fixture()
      assert {:error, %Ecto.Changeset{}} = Podcast.update_episode(episode, @invalid_attrs)
      assert episode == Podcast.get_episode!(episode.id)
    end

    test "delete_episode/1 deletes the episode" do
      episode = episode_fixture()
      assert {:ok, %Episode{}} = Podcast.delete_episode(episode)
      assert_raise Ecto.NoResultsError, fn -> Podcast.get_episode!(episode.id) end
    end

    test "change_episode/1 returns a episode changeset" do
      episode = episode_fixture()
      assert %Ecto.Changeset{} = Podcast.change_episode(episode)
    end
  end
end
