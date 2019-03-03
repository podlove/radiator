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
      assert {:ok, %Podcast{} = podcast} = Directory.create_podcast(%{title: "some title"})
      assert podcast.title == "some title"
    end

    test "create_podcast/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Directory.create_podcast(%{title: nil})
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
end
