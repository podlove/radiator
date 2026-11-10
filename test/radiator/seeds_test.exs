defmodule Radiator.SeedsTest do
  use Radiator.DataCase, async: true

  require Ash.Query

  alias Radiator.Accounts.User
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling
  alias Radiator.Podcasts.Episode.Scheduling.Access
  alias Radiator.Podcasts.Episode.Scheduling.Stats

  setup do
    Code.eval_file("priv/repo/seeds.exs")
    :ok
  end

  defp voting(title) do
    episode = Episode |> Ash.Query.filter(title == ^title) |> Ash.read_one!(authorize?: false)
    participants = Podcasts.read_scheduling_participants!(episode.id)

    scheduling =
      Scheduling
      |> Ash.get!([episode_id: episode.id], authorize?: false)
      |> Ash.load!(:organizer, authorize?: false)

    stats = Stats.voting_stats(scheduling, Enum.map(participants, & &1.id))
    %{episode: episode, participants: participants, scheduling: scheduling, stats: stats}
  end

  test "Alice organizes the first episode's vote, which has a best proposal" do
    %{episode: episode, participants: participants, scheduling: scheduling, stats: stats} =
      voting("Die erste Aufnahme")

    assert episode.state == :scheduling
    assert to_string(scheduling.organizer.email) == "alice@example.com"
    assert Enum.map(participants, & &1.name) == ["Alice", "Bob", "Carol"]
    assert %{status: :open, proposal_count: 3, total_votes: 6, all_voted?: false} = stats
    assert stats.best_proposal_id == stats.first_ranked.proposal_id
  end

  test "Bob organizes the second episode's vote, where Carol proposed a date and two tie" do
    %{episode: episode, participants: participants, scheduling: scheduling, stats: stats} =
      voting("Wer hat an der Uhr gedreht?")

    carol =
      User |> Ash.Query.filter(email == "carol@example.com") |> Ash.read_one!(authorize?: false)

    assert episode.state == :scheduling
    assert to_string(scheduling.organizer.email) == "bob@example.com"
    assert participants |> Enum.map(& &1.name) |> Enum.sort() == ["Alice", "Bob", "Carol"]
    assert Enum.any?(scheduling.proposals, &(&1.created_by_user_id == carol.id))
    assert %{status: :open, proposal_count: 4, total_votes: 11, all_voted?: false} = stats
    assert stats.best_proposal_id == nil
  end

  test "Bob is a Member, so he sees the vote he doesn't organize" do
    %{episode: episode, scheduling: scheduling} = voting("Die erste Aufnahme")
    bob = User |> Ash.Query.filter(email == "bob@example.com") |> Ash.read_one!(authorize?: false)

    assert Access.member?(episode.podcast_id, bob)

    refute Access.organizer?(
             scheduling,
             episode.podcast_id,
             bob
           )
  end
end
