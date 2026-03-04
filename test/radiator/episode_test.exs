defmodule Radiator.EpisodeTest do
  use Radiator.DataCase, async: true

  import Ash.Test

  alias Radiator.People
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
          load: [:participants]
        )

      %{podcast: podcast, episode: episode}
    end

    test "adds a participant", %{episode: episode} do
      assert episode.participants == []
      {:ok, persona} = People.create_persona(%{public_name: "prince", handle: "handle"})

      {:ok, %{participants: [added_participants]}} =
        Podcasts.add_participant_to_episode(episode, persona)

      assert_stripped added_participants == persona
    end

    test "removes a persona", %{episode: episode} do
      {:ok, persona} = People.create_persona(%{public_name: "prince", handle: "handle"})

      {:ok, %{participants: [_added_participants]}} =
        Podcasts.add_participant_to_episode(episode, persona)

      {:ok, %{participants: []}} = Podcasts.remove_participant_from_episode(episode, persona)
    end
  end
end
