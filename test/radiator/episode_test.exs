defmodule Radiator.EpisodeTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts

  describe "Episode" do
    setup do
      {:ok, podcast} = Podcasts.create_podcast(%{title: "Test Podcast"})

      {:ok, episode} =
        Podcasts.create_episode(
          %{
            title: "Test Episode",
            podcast_id: podcast.id,
            subtitle: "Test Subtitle"
          },
          load: [:personas]
        )
      %{podcast: podcast, episode: episode}
    end

    test "adds a persona", %{episode: episode} do
      assert episode.personas == []
      {:ok, persona} = Podcasts.create_persona(%{public_name: "prince", handle: "handle"})
      assert persona.public_name == "prince"
      assert persona.handle == "handle"

      {:ok, episode} = Podcasts.add_persona(episode, %{personas: [persona]})
      assert episode.personas == [persona]
    end
  end
end
