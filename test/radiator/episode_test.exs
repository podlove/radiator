defmodule Radiator.EpisodeTest do
  use Radiator.DataCase, async: true

  import Ash.Test

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

      {:ok, %{personas: [added_persona]}} = Podcasts.add_persona(episode, %{personas: [persona.id]})
      assert_stripped added_persona == persona
    end

    test "removes a persona", %{episode: episode} do
      {:ok, persona} = Podcasts.create_persona(%{public_name: "prince", handle: "handle"})
      {:ok, %{personas: [_added_persona]}} = Podcasts.add_persona(episode, %{personas: [persona.id]})

      {:ok, %{personas: []}} = Podcasts.remove_persona(episode, %{personas: [persona.id]})
    end
  end
end
