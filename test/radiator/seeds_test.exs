defmodule Radiator.SeedsTest do
  use Radiator.DataCase, async: true

  require Ash.Query

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling.Stats

  test "the seeds leave an episode whose recording date is being voted on" do
    Code.eval_file("priv/repo/seeds.exs")

    episode =
      Episode |> Ash.Query.filter(title == "Die erste Aufnahme") |> Ash.read_one!()

    participants = Podcasts.read_scheduling_participants!(episode.id)

    scheduling =
      Ash.get!(Podcasts.Episode.Scheduling, [episode_id: episode.id], authorize?: false)

    stats = Stats.voting_stats(scheduling, Enum.map(participants, & &1.id))

    assert episode.state == :scheduling
    assert Enum.map(participants, & &1.name) == ["Alice", "Bob", "Carol"]
    assert %{status: :open, proposal_count: 3, total_votes: 6, all_voted?: false} = stats
    assert stats.top_proposal_id == stats.top_proposal.proposal_id
  end
end
