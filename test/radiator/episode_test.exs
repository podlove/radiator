defmodule Radiator.EpisodeTest do
  use Radiator.DataCase, async: true

  import Ash.Test

  alias Radiator.Podcasts

  describe "Episode" do
    setup do
      %{episode: generate(episode()), persona: generate(persona())}
    end

    test "adds a participant", %{episode: episode, persona: persona} do
      {:ok, %{participants: [added_participants]}} =
        Podcasts.add_participant_to_episode(episode, persona)

      assert_stripped added_participants == persona
    end

    test "removes a participant", %{episode: episode, persona: persona} do
      {:ok, %{participants: [_added_participants]}} =
        Podcasts.add_participant_to_episode(episode, persona)

      {:ok, %{participants: []}} = Podcasts.remove_participant_from_episode(episode, persona)
    end
  end
end
