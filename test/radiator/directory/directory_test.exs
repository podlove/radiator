defmodule Radiator.DirectoryTest do
  use Radiator.DataCase

  alias Radiator.Directory

  describe "podcasts" do
    alias Radiator.Directory.Podcast

    @valid_attrs %{
      author: "some author",
      description: "some description",
      image: "some image",
      language: "some language",
      last_built_at: "2010-04-17T14:00:00Z",
      owner_email: "some owner_email",
      owner_name: "some owner_name",
      published_at: "2010-04-17T14:00:00Z",
      subtitle: "some subtitle",
      title: "some title"
    }
    @update_attrs %{
      author: "some updated author",
      description: "some updated description",
      image: "some updated image",
      language: "some updated language",
      last_built_at: "2011-05-18T15:01:01Z",
      owner_email: "some updated owner_email",
      owner_name: "some updated owner_name",
      published_at: "2011-05-18T15:01:01Z",
      subtitle: "some updated subtitle",
      title: "some updated title"
    }
    @invalid_attrs %{
      author: nil,
      description: nil,
      image: nil,
      language: nil,
      last_built_at: nil,
      owner_email: nil,
      owner_name: nil,
      published_at: nil,
      subtitle: nil,
      title: nil
    }

    def podcast_fixture(attrs \\ %{}) do
      {:ok, podcast} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Directory.create_podcast()

      podcast
    end

    test "list_podcasts/0 returns all podcasts" do
      podcast = podcast_fixture()
      assert Directory.list_podcasts() == [podcast]
    end

    test "get_podcast!/1 returns the podcast with given id" do
      podcast = podcast_fixture()
      assert Directory.get_podcast!(podcast.id) == podcast
    end

    test "create_podcast/1 with valid data creates a podcast" do
      assert {:ok, %Podcast{} = podcast} = Directory.create_podcast(@valid_attrs)
      assert podcast.author == "some author"
      assert podcast.description == "some description"
      assert podcast.image == "some image"
      assert podcast.language == "some language"
      assert podcast.last_built_at == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert podcast.owner_email == "some owner_email"
      assert podcast.owner_name == "some owner_name"
      assert podcast.published_at == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert podcast.subtitle == "some subtitle"
      assert podcast.title == "some title"
    end

    test "create_podcast/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Directory.create_podcast(@invalid_attrs)
    end

    test "update_podcast/2 with valid data updates the podcast" do
      podcast = podcast_fixture()
      assert {:ok, %Podcast{} = podcast} = Directory.update_podcast(podcast, @update_attrs)
      assert podcast.author == "some updated author"
      assert podcast.description == "some updated description"
      assert podcast.image == "some updated image"
      assert podcast.language == "some updated language"
      assert podcast.last_built_at == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert podcast.owner_email == "some updated owner_email"
      assert podcast.owner_name == "some updated owner_name"
      assert podcast.published_at == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert podcast.subtitle == "some updated subtitle"
      assert podcast.title == "some updated title"
    end

    test "update_podcast/2 with invalid data returns error changeset" do
      podcast = podcast_fixture()
      assert {:error, %Ecto.Changeset{}} = Directory.update_podcast(podcast, @invalid_attrs)
      assert podcast == Directory.get_podcast!(podcast.id)
    end

    test "delete_podcast/1 deletes the podcast" do
      podcast = podcast_fixture()
      assert {:ok, %Podcast{}} = Directory.delete_podcast(podcast)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_podcast!(podcast.id) end
    end

    test "change_podcast/1 returns a podcast changeset" do
      podcast = podcast_fixture()
      assert %Ecto.Changeset{} = Directory.change_podcast(podcast)
    end
  end

  describe "episodes" do
    alias Radiator.Directory.Episode

    @valid_attrs %{
      content: "some content",
      description: "some description",
      duration: "some duration",
      enclosure_length: "some enclosure_length",
      enclosure_type: "some enclosure_type",
      enclosure_url: "some enclosure_url",
      guid: "some guid",
      image: "some image",
      number: 42,
      published_at: "2010-04-17T14:00:00Z",
      subtitle: "some subtitle",
      title: "some title"
    }
    @update_attrs %{
      content: "some updated content",
      description: "some updated description",
      duration: "some updated duration",
      enclosure_length: "some updated enclosure_length",
      enclosure_type: "some updated enclosure_type",
      enclosure_url: "some updated enclosure_url",
      guid: "some updated guid",
      image: "some updated image",
      number: 43,
      published_at: "2011-05-18T15:01:01Z",
      subtitle: "some updated subtitle",
      title: "some updated title"
    }
    @invalid_attrs %{
      content: nil,
      description: nil,
      duration: nil,
      enclosure_length: nil,
      enclosure_type: nil,
      enclosure_url: nil,
      guid: nil,
      image: nil,
      number: nil,
      published_at: nil,
      subtitle: nil,
      title: nil
    }

    def episode_fixture(attrs \\ %{}) do
      episode_attrs =
        attrs
        |> Enum.into(@valid_attrs)

      podcast = podcast_fixture()

      {:ok, episode} = Directory.create_episode(podcast, episode_attrs)

      Repo.preload(episode, :podcast)
    end

    test "list_episodes/0 returns all episodes" do
      episode = episode_fixture()
      assert Directory.list_episodes() |> Repo.preload(:podcast) == [episode]
    end

    test "get_episode!/1 returns the episode with given id" do
      episode = episode_fixture()
      assert Directory.get_episode!(episode.id) |> Repo.preload(:podcast) == episode
    end

    test "create_episode/1 with valid data creates a episode" do
      assert {:ok, %Episode{} = episode} =
               Directory.create_episode(podcast_fixture(), @valid_attrs)

      assert episode.content == "some content"
      assert episode.description == "some description"
      assert episode.duration == "some duration"
      assert episode.enclosure_length == "some enclosure_length"
      assert episode.enclosure_type == "some enclosure_type"
      assert episode.enclosure_url == "some enclosure_url"
      assert episode.guid == "some guid"
      assert episode.image == "some image"
      assert episode.number == 42
      assert episode.published_at == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert episode.subtitle == "some subtitle"
      assert episode.title == "some title"
    end

    test "create_episode/1 with invalid data returns error changeset" do
      podcast = podcast_fixture()
      assert {:error, %Ecto.Changeset{}} = Directory.create_episode(podcast, @invalid_attrs)
    end

    test "update_episode/2 with valid data updates the episode" do
      episode = episode_fixture()
      assert {:ok, %Episode{} = episode} = Directory.update_episode(episode, @update_attrs)
      assert episode.content == "some updated content"
      assert episode.description == "some updated description"
      assert episode.duration == "some updated duration"
      assert episode.enclosure_length == "some updated enclosure_length"
      assert episode.enclosure_type == "some updated enclosure_type"
      assert episode.enclosure_url == "some updated enclosure_url"
      assert episode.guid == "some updated guid"
      assert episode.image == "some updated image"
      assert episode.number == 43
      assert episode.published_at == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert episode.subtitle == "some updated subtitle"
      assert episode.title == "some updated title"
    end

    test "update_episode/2 with invalid data returns error changeset" do
      episode = episode_fixture()
      assert {:error, %Ecto.Changeset{}} = Directory.update_episode(episode, @invalid_attrs)
      assert episode == Directory.get_episode!(episode.id) |> Repo.preload(:podcast)
    end

    test "delete_episode/1 deletes the episode" do
      episode = episode_fixture()
      assert {:ok, %Episode{}} = Directory.delete_episode(episode)
      assert_raise Ecto.NoResultsError, fn -> Directory.get_episode!(episode.id) end
    end

    test "change_episode/1 returns a episode changeset" do
      episode = episode_fixture()
      assert %Ecto.Changeset{} = Directory.change_episode(episode)
    end
  end
end
