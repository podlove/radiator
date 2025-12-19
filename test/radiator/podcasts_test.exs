defmodule Radiator.PodcastsTests do
  use Radiator.DataCase, async: true

  describe "Podcast" do
    test "can be created" do
      assert {:ok, podcast} = Radiator.Podcasts.create_podcast(%{title: "Test Podcast"})
      assert podcast.title == "Test Podcast"
    end

    test "can be read" do
      {:ok, _podcast1} = Radiator.Podcasts.create_podcast(%{title: "Podcast 1"})
      {:ok, _podcast2} = Radiator.Podcasts.create_podcast(%{title: "Podcast 2"})

      assert {:ok, podcasts} = Radiator.Podcasts.read_podcasts()
      assert length(podcasts) >= 2
    end

    test "can be retrieved by id" do
      {:ok, podcast} = Radiator.Podcasts.create_podcast(%{title: "Test Podcast"})

      assert {:ok, retrieved} = Radiator.Podcasts.get_podcast_by_id(podcast.id)
      assert retrieved.id == podcast.id
      assert retrieved.title == "Test Podcast"
    end

    test "can be updated" do
      {:ok, podcast} = Radiator.Podcasts.create_podcast(%{title: "Original Title"})

      assert {:ok, updated} =
               Radiator.Podcasts.update_podcast(podcast, %{title: "Updated Title"})

      assert updated.title == "Updated Title"
    end

    test "can be destroyed" do
      {:ok, podcast} = Radiator.Podcasts.create_podcast(%{title: "Test Podcast"})

      assert :ok = Radiator.Podcasts.destroy_podcast(podcast)
      assert {:error, _} = Radiator.Podcasts.get_podcast_by_id(podcast.id)
    end
  end

  describe "Episode" do
    setup do
      {:ok, podcast} = Radiator.Podcasts.create_podcast(%{title: "Test Podcast"})
      %{podcast: podcast}
    end

    test "can be created", %{podcast: podcast} do
      assert {:ok, episode} =
               Radiator.Podcasts.create_episode(%{
                 title: "Test Episode",
                 podcast_id: podcast.id,
                 subtitle: "Test Subtitle"
               })

      assert episode.title == "Test Episode"
    end

    test "can be read", %{podcast: podcast} do
      {:ok, _episode1} =
        Radiator.Podcasts.create_episode(%{
          title: "Episode 1",
          podcast_id: podcast.id
        })

      {:ok, _episode2} =
        Radiator.Podcasts.create_episode(%{
          title: "Episode 2",
          podcast_id: podcast.id
        })

      assert {:ok, episodes} = Radiator.Podcasts.read_episodes()
      assert length(episodes) >= 2
    end

    test "can be retrieved by id", %{podcast: podcast} do
      {:ok, episode} =
        Radiator.Podcasts.create_episode(%{
          title: "Test Episode",
          podcast_id: podcast.id
        })

      assert {:ok, retrieved} = Radiator.Podcasts.get_episode_by_id(episode.id)
      assert retrieved.id == episode.id
      assert retrieved.title == "Test Episode"
    end

    test "can be updated", %{podcast: podcast} do
      {:ok, episode} =
        Radiator.Podcasts.create_episode(%{
          title: "Original Title",
          podcast_id: podcast.id
        })

      assert {:ok, updated} =
               Radiator.Podcasts.update_episode(episode, %{title: "Updated Title"})

      assert updated.title == "Updated Title"
    end
  end
end
