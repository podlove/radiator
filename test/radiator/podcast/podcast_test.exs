defmodule Radiator.PodcastTest do
  use Radiator.DataCase

  alias Radiator.Podcast

  describe "shows" do
    alias Radiator.Podcast.Show

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

    def show_fixture(attrs \\ %{}) do
      {:ok, show} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Podcast.create_show()

      show
    end

    test "list_shows/0 returns all shows" do
      show = show_fixture()
      assert Podcast.list_shows() == [show]
    end

    test "get_show!/1 returns the show with given id" do
      show = show_fixture()
      assert Podcast.get_show!(show.id) == show
    end

    test "create_show/1 with valid data creates a show" do
      assert {:ok, %Show{} = show} = Podcast.create_show(@valid_attrs)
      assert show.author == "some author"
      assert show.description == "some description"
      assert show.image == "some image"
      assert show.language == "some language"
      assert show.last_built_at == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert show.owner_email == "some owner_email"
      assert show.owner_name == "some owner_name"
      assert show.published_at == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert show.subtitle == "some subtitle"
      assert show.title == "some title"
    end

    # test "create_show/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Podcast.create_show(@invalid_attrs)
    # end

    test "update_show/2 with valid data updates the show" do
      show = show_fixture()
      assert {:ok, %Show{} = show} = Podcast.update_show(show, @update_attrs)
      assert show.author == "some updated author"
      assert show.description == "some updated description"
      assert show.image == "some updated image"
      assert show.language == "some updated language"
      assert show.last_built_at == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert show.owner_email == "some updated owner_email"
      assert show.owner_name == "some updated owner_name"
      assert show.published_at == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert show.subtitle == "some updated subtitle"
      assert show.title == "some updated title"
    end

    # test "update_show/2 with invalid data returns error changeset" do
    #   show = show_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Podcast.update_show(show, @invalid_attrs)
    #   assert show == Podcast.get_show!(show.id)
    # end

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
    alias Radiator.Podcast.Episode

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
      {:ok, episode} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Podcast.create_episode()

      episode
    end

    test "list_episodes/0 returns all episodes" do
      episode = episode_fixture()
      assert Podcast.list_episodes() == [episode]
    end

    test "get_episode!/1 returns the episode with given id" do
      episode = episode_fixture()
      assert Podcast.get_episode!(episode.id) == episode
    end

    test "create_episode/1 with valid data creates a episode" do
      assert {:ok, %Episode{} = episode} = Podcast.create_episode(@valid_attrs)
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

    # test "create_episode/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Podcast.create_episode(@invalid_attrs)
    # end

    test "update_episode/2 with valid data updates the episode" do
      episode = episode_fixture()
      assert {:ok, %Episode{} = episode} = Podcast.update_episode(episode, @update_attrs)
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

    # test "update_episode/2 with invalid data returns error changeset" do
    #   episode = episode_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Podcast.update_episode(episode, @invalid_attrs)
    #   assert episode == Podcast.get_episode!(episode.id)
    # end

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
