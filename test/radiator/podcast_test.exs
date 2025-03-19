defmodule Radiator.PodcastTest do
  use Radiator.DataCase

  import Radiator.PodcastFixtures
  import Radiator.AccountsFixtures

  alias Radiator.Podcast
  alias Radiator.Podcast.{Episode, Network, Show}

  describe "networks" do
    @invalid_attrs %{title: nil}

    test "list_networks/0 returns all networks" do
      network = network_fixture()
      assert Podcast.list_networks() |> Enum.map(& &1.id) == [network.id]
    end

    test "list_networks/1 returns all networks with preloaded shows" do
      show = show_fixture()
      assert [%Network{shows: shows}] = Podcast.list_networks(preload: :shows)
      assert shows |> Enum.map(& &1.id) == [show.id]
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
    @invalid_attrs %{title: nil}

    test "list_shows/0 returns all shows" do
      assert Podcast.list_shows() == []
      show = show_fixture()

      assert Podcast.list_shows() |> Enum.map(& &1.id) == [show.id]
    end

    test "get_show!/1 returns the show with given id" do
      show = show_fixture()
      show_id = show.id
      assert %Show{id: ^show_id} = Podcast.get_show!(show_id)
    end

    test "get_show_preloaded!/1 returns the show with preloaded episodes" do
      show = show_fixture()
      episode = episode_fixture(%{show_id: show.id})

      assert %Show{episodes: episodes} = Podcast.get_show_preloaded!(show.id)
      assert episodes |> Enum.map(& &1.id) == [episode.id]
    end

    test "create_show/1 with valid data creates a show" do
      network = network_fixture()
      valid_attrs = %{title: "some title", network_id: network.id}

      assert {:ok, %Show{} = show} = Podcast.create_show(valid_attrs)
      assert show.title == "some title"
      assert show.network_id == network.id
    end

    test "create_show/1 creates global inbox and global root nodes" do
      network = network_fixture()
      valid_attrs = %{title: "some title", network_id: network.id}

      {:ok, %Show{} = show} = Podcast.create_show(valid_attrs)
      refute(is_nil(show.inbox_node_container_id))
    end

    test "create_show/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Podcast.create_show(@invalid_attrs)
    end

    test "create_show/2 with valid data creates a show with hosts" do
      network = network_fixture()
      valid_attrs = %{title: "some title", network_id: network.id}

      hosts = [
        user_fixture(%{email: "bob@example.com"}),
        user_fixture(%{email: "jim@example.com"})
      ]

      assert {:ok, %Show{} = show} = Podcast.create_show(valid_attrs, hosts)
      assert show.title == "some title"
      assert show.network_id == network.id
      show = Repo.preload(show, :hosts)
      assert show.hosts == hosts
    end

    test "create_show/2 with invalid data returns error changeset" do
      invalid_attrs = %{title: nil, network_id: nil}

      hosts = [
        user_fixture(%{email: "bob@example.com"}),
        user_fixture(%{email: "jim@example.com"})
      ]

      assert {:error, %Ecto.Changeset{}} = Podcast.create_show(invalid_attrs, hosts)
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
    end

    test "update_show/2 with valid data updates the show by removing hosts" do
      init_hosts = [
        user_fixture(%{email: "bob@example.com"}),
        user_fixture(%{email: "jim@example.com"})
      ]

      show = show_fixture(%{}, init_hosts)

      assert {:ok, %Show{} = show} = Podcast.update_show(show, %{}, [])
      show = Podcast.reload_assoc(show, [:hosts])
      assert show.hosts == []
    end

    test "update_show/2 with valid data updates the show by adding hosts" do
      updated_hosts = [
        user_fixture(%{email: "bob@example.com"}),
        user_fixture(%{email: "jim@example.com"})
      ]

      show = show_fixture(%{}, [])

      assert {:ok, %Show{} = show} = Podcast.update_show(show, %{}, updated_hosts)
      show = Podcast.reload_assoc(show, [:hosts])
      assert show.hosts == updated_hosts
    end

    test "update_show/2 with valid data updates the show by adding and removing hosts" do
      init_hosts = [user_fixture(%{email: "bob@example.com"})]
      updated_hosts = [user_fixture(%{email: "jim@example.com"})]

      show = show_fixture(%{}, init_hosts)

      assert {:ok, %Show{} = show} = Podcast.update_show(show, %{}, updated_hosts)
      show = Podcast.reload_assoc(show, [:hosts])
      assert show.hosts == updated_hosts
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

    test "list_all_episodes/0 returns also deleted episodes" do
      deleted_episode =
        episode_fixture(
          is_deleted: true,
          deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)
        )

      assert Enum.map(Podcast.list_all_episodes(), fn e -> e.id end) == [deleted_episode.id]
    end

    test "list_available_episodes/0 returns all episodes" do
      episode = episode_fixture()

      _deleted_episode =
        episode_fixture(
          is_deleted: true,
          deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)
        )

      assert Podcast.list_available_episodes() |> Enum.map(& &1.id) == [episode.id]
    end

    test "get_episode!/1 returns the episode with given id" do
      episode = episode_fixture()
      episode_id = episode.id
      assert %Episode{id: ^episode_id} = Podcast.get_episode!(episode.id)
    end

    test "create_episode/1 with valid data creates a episode" do
      show = show_fixture()
      valid_attrs = %{title: "some title", show_id: show.id, number: 5}

      assert {:ok, %Episode{} = episode} = Podcast.create_episode(valid_attrs)
      assert episode.title == "some title"
      assert episode.show_id == show.id
      assert episode.number == 5
      assert episode.slug == "some-title"
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
      assert episode.slug == "some-updated-title"
    end

    test "create_episode/1 creates node container" do
      show = show_fixture()
      valid_attrs = %{title: "some title", show_id: show.id, number: 5}

      assert {:ok, %Episode{} = episode} = Podcast.create_episode(valid_attrs)
      refute(is_nil(episode.outline_node_container_id))
    end

    test "update_episode/2 with invalid data returns error changeset" do
      episode = episode_fixture()
      assert {:error, %Ecto.Changeset{}} = Podcast.update_episode(episode, @invalid_attrs)
    end

    test "delete_episode/1 deletes the episode" do
      episode = episode_fixture()
      assert {:ok, %Episode{}} = Podcast.delete_episode(episode)
      episode = Podcast.get_episode!(episode.id)
      assert episode.is_deleted == true
      assert episode.deleted_at != nil

      assert Podcast.list_available_episodes() == []
    end

    test "change_episode/1 returns a episode changeset" do
      episode = episode_fixture()
      assert %Ecto.Changeset{} = Podcast.change_episode(episode)
    end

    test "get_current_episode_for_show/1 returns nil when no show has been given" do
      assert nil == Podcast.get_current_episode_for_show(nil)
    end

    test "get_current_episode_for_show/1 returns nil when no episode for show exists" do
      show = show_fixture()
      assert nil == Podcast.get_current_episode_for_show(show.id)
    end

    test "get_current_episode_for_show/1 returns episdoe for show" do
      episode = episode_fixture()
      assert episode.id == Podcast.get_current_episode_for_show(episode.show_id).id
    end

    test "get_current_episode_for_show/1 returns the episode with the highest number" do
      show = show_fixture()
      # create new before old to ensure that the highest number is returned
      # and not just the newest
      episode_new = episode_fixture(number: 23, show_id: show.id)
      _episode_old = episode_fixture(number: 22, show_id: show.id)
      assert episode_new.id == Podcast.get_current_episode_for_show(show.id).id
    end

    test "get_current_episode_for_show/1 sets the inbox_container_id virtual field from show" do
      show = show_fixture()
      episode_fixture(number: 23, show_id: show.id)

      assert show.inbox_node_container_id ==
               Podcast.get_current_episode_for_show(show.id).inbox_node_container_id
    end
  end
end
