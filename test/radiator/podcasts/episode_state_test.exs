defmodule Radiator.Podcasts.EpisodeStateTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode

  setup do
    owner = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Show"}, actor: owner)

    %{podcast: podcast}
  end

  defp transition(episode, action), do: Ash.update(episode, %{}, action: action)

  defp upsert_from_feed!(podcast, attrs) do
    [attrs |> Map.put(:podcast_id, podcast.id)]
    |> Ash.bulk_create!(Episode, :upsert_from_feed, return_records?: true, authorize?: false)
    |> Map.fetch!(:records)
    |> hd()
  end

  test "a hand-created episode starts in scheduling", %{podcast: podcast} do
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "One"})

    assert episode.state == :scheduling
  end

  test "an episode from the feed is published", %{podcast: podcast} do
    episode = upsert_from_feed!(podcast, %{title: "From the feed", guid: "item-1"})

    assert episode.state == :published
  end

  test "a feed sync publishes a hand-created episode it matches", %{podcast: podcast} do
    Podcasts.create_episode!(%{podcast_id: podcast.id, title: "One", guid: "item-1"})

    assert upsert_from_feed!(podcast, %{title: "One", guid: "item-1"}).state == :published
  end

  test "choosing a date schedules the episode and giving it up goes back", %{podcast: podcast} do
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "One"})

    assert {:ok, %{state: :scheduled} = scheduled} = transition(episode, :finalize_scheduling)
    assert {:ok, %{state: :scheduling}} = transition(scheduled, :back_to_scheduling)
  end

  test "only a scheduling episode can be scheduled", %{podcast: podcast} do
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "One"})
    {:ok, scheduled} = transition(episode, :finalize_scheduling)

    assert {:error, _} = transition(scheduled, :finalize_scheduling)
    assert {:error, _} = transition(episode, :back_to_scheduling)
  end

  test "a published episode cannot go back to scheduling", %{podcast: podcast} do
    episode = upsert_from_feed!(podcast, %{title: "From the feed", guid: "item-1"})

    assert {:error, _} = transition(episode, :back_to_scheduling)
    assert {:error, _} = transition(episode, :finalize_scheduling)
  end
end
