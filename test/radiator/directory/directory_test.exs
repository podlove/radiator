defmodule Radiator.DirectoryTest do
  use Radiator.DataCase

  alias Radiator.Directory
  alias Radiator.Directory.Editor

  import Radiator.Factory

  describe "podcasts" do
    alias Radiator.Directory.Podcast

    test "list_podcasts/0 returns only public podcasts" do
      _podcast = insert(:podcast)
      podcast = insert(:podcast) |> publish()
      assert Directory.list_podcasts() |> Repo.preload(:network) == [podcast]
    end

    test "get_podcast/1 returns the podcast with given id if it is public" do
      podcast = insert(:podcast) |> publish()

      assert Directory.get_podcast(podcast.id) |> Repo.preload([:network, :contributions]) ==
               podcast |> Repo.preload([:network, :contributions])

      podcast2 = insert(:podcast)

      assert is_nil(Directory.get_podcast(podcast2.id))
    end

    test "get_episodes_count_for_podcast!/1 return the number of episodes" do
      podcast = insert(:podcast) |> publish()

      assert Directory.get_episodes_count_for_podcast!(podcast.id) == 0

      _episode1 = insert(:episode, podcast: podcast) |> publish()
      _episode2 = insert(:episode, podcast: podcast) |> publish()
      _episode3 = insert(:episode, podcast: podcast)

      assert Directory.get_episodes_count_for_podcast!(podcast.id) == 2
    end

    test "get_podcast_by_slug/1 returns the podcast with given slug" do
      podcast = insert(:podcast, slug: "podcast-foo-bar-baz") |> publish()

      assert Directory.get_podcast_by_slug(podcast.slug)
             |> Repo.preload([:network, :contributions]) ==
               podcast |> Repo.preload([:network, :contributions])
    end

    test "create_podcast/1 with valid data creates a podcast" do
      network = insert(:network)

      assert {:ok, %Podcast{} = podcast} =
               Editor.Manager.create_podcast(network, %{title: "some title"})

      assert podcast.title == "some title"
    end

    test "create_podcast/1 with invalid data returns error changeset" do
      network = insert(:network)
      assert {:error, %Ecto.Changeset{}} = Editor.Manager.create_podcast(network, %{title: nil})
    end

    test "update_podcast/2 with valid data updates the podcast" do
      podcast = insert(:podcast) |> publish()

      assert {:ok, %Podcast{} = podcast} =
               Editor.Manager.update_podcast(podcast, %{subtitle: "some updated subtitle"})

      assert podcast.subtitle == "some updated subtitle"
    end

    test "update_podcast/2 with invalid data returns error changeset" do
      podcast = insert(:podcast) |> publish()

      assert {:error, %Ecto.Changeset{}} = Editor.Manager.update_podcast(podcast, %{title: nil})

      assert podcast |> Repo.preload([:network, :contributions]) ==
               Directory.get_podcast(podcast.id) |> Repo.preload([:network, :contributions])
    end

    test "delete_podcast/1 deletes the podcast" do
      podcast = insert(:podcast) |> publish()
      assert {:ok, %Podcast{}} = Editor.Manager.delete_podcast(podcast)
      assert is_nil(Directory.get_podcast(podcast.id))
    end

    test "change_podcast/1 returns a podcast changeset" do
      podcast = insert(:podcast) |> publish()
      assert %Ecto.Changeset{} = Editor.Manager.change_podcast(podcast)
    end

    test "publish/1 sets a published_at date" do
      podcast = insert(:podcast, published_at: nil)

      assert {:ok, %Podcast{} = published_podcast} = Editor.Manager.publish(podcast)
      assert published_podcast.published_at != nil
      assert :gt == DateTime.compare(DateTime.utc_now(), published_podcast.published_at)
    end

    test "publish/1 generates a slug from title" do
      podcast = insert(:podcast, published_at: nil)

      {:ok, published_podcast} = Editor.Manager.publish(podcast)
      assert is_binary(published_podcast.slug)
      assert String.length(published_podcast.slug) > 0
    end

    test "publish/1 generates sequential slugs" do
      {:ok, existing_podcast} =
        insert(:podcast)
        |> publish()
        |> Editor.Manager.publish()

      {:ok, published_podcast1} =
        insert(:podcast, title: existing_podcast.title)
        |> Editor.Manager.publish()

      assert published_podcast1.slug == "#{existing_podcast.slug}-1"

      {:ok, published_podcast2} =
        insert(:podcast, title: existing_podcast.title)
        |> Editor.Manager.publish()

      assert published_podcast2.slug == "#{existing_podcast.slug}-2"

      {:ok, published_podcast3} =
        insert(:podcast, title: existing_podcast.title)
        |> Editor.Manager.publish()

      assert published_podcast3.slug == "#{existing_podcast.slug}-3"
    end

    test "depublish/1 sets podcasts state to :depublished" do
      podcast = insert(:podcast) |> publish()
      published_at = podcast.published_at

      assert {:ok, %Podcast{published_at: ^published_at, publish_state: :depublished}} =
               Editor.Manager.depublish(podcast)
    end
  end

  describe "episodes" do
    alias Radiator.Directory.Episode

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    test "list_episodes/0 returns all episodes" do
      episode = insert(:episode) |> publish()
      episode_id = episode.id

      assert [%Episode{id: ^episode_id}] = Directory.list_episodes()
    end

    test "get_episode/1 returns the episode with given id" do
      episode = insert(:episode) |> publish()
      episode_id = episode.id

      assert %Episode{id: ^episode_id} = Directory.get_episode(episode.id)
    end

    test "get_episode_by_slug/1 returns the episode with given slug" do
      episode = insert(:episode, slug: "episode-foo-bar-baz") |> publish_all()
      episode_id = episode.id

      assert %Episode{id: ^episode_id} =
               Directory.get_episode_by_slug(episode.podcast_id, episode.slug)
    end

    test "create_episode/1 with valid data creates an episode" do
      assert {:ok, %Episode{} = episode} =
               Editor.Manager.create_episode(insert(:podcast) |> publish(), @valid_attrs)

      assert episode.title == "some title"
    end

    test "create_episode/1 with invalid data returns error changeset" do
      podcast = insert(:podcast) |> publish()

      assert {:error, %Ecto.Changeset{}} = Editor.Manager.create_episode(podcast, @invalid_attrs)
    end

    test "update_episode/2 with valid data updates the episode" do
      episode = insert(:episode)
      assert {:ok, %Episode{} = episode} = Editor.Manager.update_episode(episode, @update_attrs)
      assert episode.title == "some updated title"
    end

    test "update_episode/2 doesn't generate slug when episode is not published" do
      episode = insert(:episode, publish_state: :drafted)

      {:ok, updated_episode} =
        Editor.Manager.update_episode(episode, %{title: "some updated episode title"})

      assert updated_episode.slug == nil

      {:ok, published_episode} = Editor.Manager.publish(updated_episode)

      assert String.length(published_episode.slug) > 0
    end

    test "update_episode/2 with invalid data returns error changeset" do
      episode = insert(:episode)
      assert {:error, %Ecto.Changeset{}} = Editor.Manager.update_episode(episode, @invalid_attrs)
    end

    test "delete_episode/1 deletes the episode" do
      episode = insert(:episode)
      assert {:ok, %Episode{}} = Editor.Manager.delete_episode(episode)
      assert is_nil(Directory.get_episode(episode.id))
    end

    test "change_episode/1 returns an episode changeset" do
      episode = insert(:episode)
      assert %Ecto.Changeset{} = Editor.Manager.change_episode(episode)
    end

    test "publish_episode/1 sets a published_at date" do
      episode = insert(:episode, published_at: nil)

      assert {:ok, %Episode{} = published_episode} = Editor.Manager.publish(episode)
      assert published_episode.publish_state == :published
      assert published_episode.published_at != nil
      assert :gt == DateTime.compare(DateTime.utc_now(), published_episode.published_at)
    end

    test "publish_episode/1 generates a slug from title" do
      episode = insert(:episode, published_at: nil)

      {:ok, published_episode} = Editor.Manager.publish(episode)
      assert is_binary(published_episode.slug)
      assert String.length(published_episode.slug) > 0
    end

    test "publish_episode/1 generates sequential slugs" do
      podcast = insert(:podcast) |> publish()

      {:ok, existing_episode} =
        insert(:episode, %{podcast: podcast})
        |> Editor.Manager.publish()

      {:ok, published_episode1} =
        insert(:episode,
          title: existing_episode.title,
          podcast: podcast
        )
        |> Editor.Manager.publish()

      assert published_episode1.slug == "#{existing_episode.slug}-1"

      {:ok, published_episode2} =
        insert(:episode,
          title: existing_episode.title,
          podcast: podcast
        )
        |> Editor.Manager.publish()

      assert published_episode2.slug == "#{existing_episode.slug}-2"

      {:ok, published_episode3} =
        insert(:episode,
          title: existing_episode.title,
          podcast: podcast
        )
        |> Editor.Manager.publish()

      assert published_episode3.slug == "#{existing_episode.slug}-3"
    end
  end

  describe "networks" do
    alias Radiator.Directory.Network

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    def network_fixture(attrs \\ %{}) do
      testuser = Radiator.TestEntries.user()

      {:ok, network} = Editor.Owner.create_network(testuser, Enum.into(attrs, @valid_attrs))

      network
    end

    test "list_networks/0 returns all networks" do
      network = network_fixture()
      insert(:podcast, network: network) |> publish()
      assert Directory.list_networks() == [network]
    end

    test "get_network!/1 returns the network with given id" do
      network = network_fixture()
      insert(:podcast, network: network) |> publish()

      assert Directory.get_network!(network.id) == network
    end

    test "get_network_by_slug/1 returns the network with given slug" do
      network = insert(:network, slug: "network-foo-bar-baz")
      insert(:podcast, network: network) |> publish()

      assert Directory.get_network_by_slug(network.slug) == network
    end

    test "create_network/1 with valid data creates a network" do
      testuser = Radiator.TestEntries.user()

      assert {:ok, network} = Editor.Owner.create_network(testuser, @valid_attrs)

      assert network.title == "some title"
    end

    test "create_network/1 generates a slug from the new networks title" do
      testuser = Radiator.TestEntries.user()

      assert {:ok, network} = Editor.Owner.create_network(testuser, %{title: "Network Slug Test"})

      assert network.slug == "network-slug-test"
    end

    test "create_network/1 with invalid data returns error changeset" do
      testuser = Radiator.TestEntries.user()

      assert {:error, network_changeset} = Editor.Owner.create_network(testuser, @invalid_attrs)
    end

    test "update_network/2 with valid data updates the network" do
      network = network_fixture()
      assert {:ok, %Network{} = network} = Editor.Owner.update_network(network, @update_attrs)
      assert network.title == "some updated title"
    end

    test "update_network/2 with invalid data returns error changeset" do
      network = network_fixture()
      insert(:podcast, network: network) |> publish()

      assert {:error, %Ecto.Changeset{}} = Editor.Owner.update_network(network, @invalid_attrs)
      assert network == Directory.get_network!(network.id)
    end

    test "delete_network/1 deletes the network" do
      network = network_fixture()
      assert {:ok, %Network{}} = Editor.Owner.delete_network(network)
      assert is_nil(Directory.get_network(network.id))
    end
  end

  describe "audio files" do
    alias Radiator.Media.AudioFile

    test "get_audio_file/1 returns audio file" do
      episode = insert(:episode) |> publish()
      audio = Ecto.assoc(episode, [:audio]) |> Repo.one()
      [audio_file] = Ecto.assoc(audio, :audio_files) |> Repo.all()

      file = audio_file.file

      assert {:ok, %AudioFile{file: ^file}} = Directory.get_audio_file(audio_file.id)
    end

    test "get_audio_file/1 errors when accessing unpublished audio file" do
      episode = insert(:episode)
      audio = Ecto.assoc(episode, [:audio]) |> Repo.one()
      [audio_file] = Ecto.assoc(audio, :audio_files) |> Repo.all()

      assert {:error, :unpublished} = Directory.get_audio_file(audio_file.id)
    end

    test "get_audio_file/1 errors when accessing nonexisting audio file" do
      assert {:error, :not_found} = Directory.get_audio_file(1)
    end
  end
end
