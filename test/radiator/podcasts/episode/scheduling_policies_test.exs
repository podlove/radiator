defmodule Radiator.Podcasts.Episode.SchedulingPoliciesTest do
  @moduledoc "Who may do what with a scheduling (spec 04, ADR 0001 §5, ADR 0002)."

  use Radiator.DataCase, async: true

  require Ash.Query

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode.Scheduling
  alias Radiator.Podcasts.EpisodeContributor
  alias Radiator.Podcasts.Person
  alias Radiator.Podcasts.PodcastUserRole

  @fri ~U[2026-11-06 19:00:00Z]
  @sat ~U[2026-11-07 10:00:00Z]

  setup do
    owner = generate(user())
    member = generate(user())
    contributor = generate(user())
    stranger = generate(user())

    podcast = Podcasts.create_podcast!(%{title: "Show"}, actor: owner)

    Ash.create!(PodcastUserRole, %{podcast_id: podcast.id, user_id: member.id, role: :owner},
      authorize?: false
    )

    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "One"})
    other_episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Two"})
    contribute!(episode, owner, "Contributor", contributor)
    contribute!(other_episode, owner, "Stranger", stranger)

    scheduling = Podcasts.start_scheduling!(episode.id, [@fri], actor: owner)

    %{
      owner: owner,
      member: member,
      contributor: contributor,
      stranger: stranger,
      episode: episode,
      scheduling: scheduling,
      proposal: hd(scheduling.proposals)
    }
  end

  defp contribute!(episode, owner, name, account) do
    person =
      Ash.create!(Person, %{name: name, user_id: owner.id, account_id: account.id},
        action: :create
      )

    Ash.create!(EpisodeContributor, %{episode_id: episode.id, person_id: person.id})
  end

  # The Organizer leaves the podcast but stays credited on the episode.
  defp leave_podcast!(scheduling, user) do
    episode = Ash.get!(Radiator.Podcasts.Episode, scheduling.episode_id, authorize?: false)

    PodcastUserRole
    |> Ash.Query.filter(podcast_id == ^episode.podcast_id and user_id == ^user.id)
    |> Ash.read_one!(authorize?: false)
    |> Ash.destroy!(authorize?: false)
  end

  # What deleting the Organizer's account leaves behind (`on_delete: :nilify`).
  defp lose_organizer!(scheduling) do
    Radiator.Repo.query!(
      "UPDATE episode_schedulings SET organizer_id = NULL WHERE id = $1",
      [Ecto.UUID.dump!(scheduling.id)]
    )

    Ash.get!(Scheduling, scheduling.id, authorize?: false)
  end

  defp forbidden?({:error, %Ash.Error.Forbidden{}}), do: true
  defp forbidden?(_result), do: false

  describe "read" do
    test "members and contributors see the scheduling", %{
      episode: episode,
      member: member,
      contributor: contributor
    } do
      for actor <- [member, contributor] do
        assert {:ok, %Scheduling{}} = Podcasts.get_scheduling_by_episode(episode.id, actor: actor)
      end
    end

    test "anybody else sees nothing", %{episode: episode, stranger: stranger} do
      assert {:error, _not_found} =
               Podcasts.get_scheduling_by_episode(episode.id, actor: stranger)

      assert {:error, _not_found} = Podcasts.get_scheduling_by_episode(episode.id)
    end
  end

  describe "start" do
    setup %{episode: episode} do
      %{fresh: Podcasts.create_episode!(%{podcast_id: episode.podcast_id, title: "New"})}
    end

    test "a member starts a scheduling", %{fresh: fresh, member: member} do
      assert {:ok, _} = Podcasts.start_scheduling(fresh.id, [@fri], actor: member)
    end

    test "contributors, strangers and nobody cannot", %{
      fresh: fresh,
      contributor: contributor,
      stranger: stranger
    } do
      for actor <- [contributor, stranger] do
        assert forbidden?(Podcasts.start_scheduling(fresh.id, [@fri], actor: actor))
      end

      # Without an actor there is nobody to relate as creator; that fails first.
      assert {:error, _} = Podcasts.start_scheduling(fresh.id, [@fri])
    end
  end

  describe "proposals" do
    test "members and contributors propose dates", %{
      scheduling: scheduling,
      member: member,
      contributor: contributor
    } do
      scheduling = Podcasts.add_scheduling_proposal!(scheduling, @sat, actor: contributor)

      assert {:ok, _} =
               Podcasts.add_scheduling_proposal(scheduling, ~U[2026-11-08 19:00:00Z],
                 actor: member
               )
    end

    test "a stranger cannot propose or remove dates", %{
      scheduling: scheduling,
      proposal: proposal,
      stranger: stranger
    } do
      assert forbidden?(Podcasts.add_scheduling_proposal(scheduling, @sat, actor: stranger))

      # Removing somebody else's proposal is refused by its validation before
      # the policies run.
      assert {:error, _} =
               Podcasts.remove_scheduling_proposal(scheduling, proposal.id, actor: stranger)
    end

    test "the Organizer removes a proposal somebody else made", %{
      scheduling: scheduling,
      contributor: contributor,
      owner: owner
    } do
      scheduling = Podcasts.add_scheduling_proposal!(scheduling, @sat, actor: contributor)
      theirs = Enum.find(scheduling.proposals, &(&1.created_by_user_id == contributor.id))

      assert {:ok, _} = Podcasts.remove_scheduling_proposal(scheduling, theirs.id, actor: owner)
    end

    test "another member removes only their own proposals", %{
      scheduling: scheduling,
      proposal: proposal,
      member: member
    } do
      assert {:error, _} =
               Podcasts.remove_scheduling_proposal(scheduling, proposal.id, actor: member)

      scheduling = Podcasts.add_scheduling_proposal!(scheduling, @sat, actor: member)
      own = Enum.find(scheduling.proposals, &(&1.created_by_user_id == member.id))

      assert {:ok, _} = Podcasts.remove_scheduling_proposal(scheduling, own.id, actor: member)
    end
  end

  describe "vote" do
    test "a contributor votes", %{
      scheduling: scheduling,
      proposal: proposal,
      contributor: contributor
    } do
      assert {:ok, _} = Podcasts.vote_on_proposal(scheduling, proposal.id, 1, actor: contributor)
      assert {:ok, _} = Podcasts.remove_vote(scheduling, proposal.id, actor: contributor)
    end

    test "a member who is no contributor, a contributor of another episode and nobody cannot", %{
      scheduling: scheduling,
      proposal: proposal,
      member: member,
      stranger: stranger
    } do
      for actor <- [member, stranger, nil] do
        assert {:error, _} = Podcasts.vote_on_proposal(scheduling, proposal.id, 1, actor: actor)
        assert {:error, _} = Podcasts.remove_vote(scheduling, proposal.id, actor: actor)
      end
    end

    test "a member who also contributes votes", %{
      scheduling: scheduling,
      proposal: proposal,
      episode: episode,
      owner: owner,
      member: member
    } do
      contribute!(episode, owner, "Member", member)

      assert {:ok, _} = Podcasts.vote_on_proposal(scheduling, proposal.id, 0, actor: member)
    end
  end

  describe "finalize, reopen and destroy" do
    test "the member who started it decides and reopens", %{
      scheduling: scheduling,
      proposal: proposal,
      owner: owner
    } do
      scheduling = Podcasts.finalize_scheduling!(scheduling, proposal.id, actor: owner)

      assert {:ok, _} = Podcasts.reopen_scheduling(scheduling, actor: owner)
    end

    test "other members, contributors, strangers and nobody cannot decide", %{
      scheduling: scheduling,
      proposal: proposal,
      member: member,
      contributor: contributor,
      stranger: stranger
    } do
      for actor <- [member, contributor, stranger, nil] do
        assert forbidden?(Podcasts.finalize_scheduling(scheduling, proposal.id, actor: actor))
      end
    end

    test "other members and contributors cannot reopen", %{
      scheduling: scheduling,
      proposal: proposal,
      owner: owner,
      member: member,
      contributor: contributor
    } do
      scheduling = Podcasts.finalize_scheduling!(scheduling, proposal.id, actor: owner)

      for actor <- [member, contributor] do
        assert forbidden?(Podcasts.reopen_scheduling(scheduling, actor: actor))
      end
    end

    test "only the Organizer deletes a scheduling", %{
      scheduling: scheduling,
      owner: owner,
      member: member,
      contributor: contributor
    } do
      assert forbidden?(Ash.destroy(scheduling, actor: contributor))
      assert forbidden?(Ash.destroy(scheduling, actor: member))
      assert :ok = Ash.destroy(scheduling, actor: owner)
    end

    test "an Organizer who left the podcast decides no more but still votes", %{
      scheduling: scheduling,
      proposal: proposal,
      owner: owner
    } do
      leave_podcast!(scheduling, owner)

      assert forbidden?(Podcasts.finalize_scheduling(scheduling, proposal.id, actor: owner))
      assert forbidden?(Ash.destroy(scheduling, actor: owner))
      assert {:ok, _} = Podcasts.vote_on_proposal(scheduling, proposal.id, 1, actor: owner)
    end
  end

  describe "take over" do
    test "nobody takes over while the Organizer is a member", %{
      scheduling: scheduling,
      member: member
    } do
      assert {:error, %Ash.Error.Invalid{}} =
               Podcasts.take_over_scheduling(scheduling, actor: member)
    end

    test "a member takes over from an Organizer who left, then decides and votes", %{
      scheduling: scheduling,
      proposal: proposal,
      owner: owner,
      member: member
    } do
      leave_podcast!(scheduling, owner)

      scheduling = Podcasts.take_over_scheduling!(scheduling, actor: member)

      assert scheduling.organizer_id == member.id
      assert {:ok, _} = Podcasts.vote_on_proposal(scheduling, proposal.id, 1, actor: member)
      assert {:ok, _} = Podcasts.finalize_scheduling(scheduling, proposal.id, actor: member)
    end

    test "a member takes over a closed scheduling whose Organizer's account is gone and reopens it",
         %{scheduling: scheduling, proposal: proposal, owner: owner, member: member} do
      scheduling = Podcasts.finalize_scheduling!(scheduling, proposal.id, actor: owner)
      scheduling = lose_organizer!(scheduling)

      scheduling = Podcasts.take_over_scheduling!(scheduling, actor: member)

      assert {:ok, %{status: :open}} = Podcasts.reopen_scheduling(scheduling, actor: member)
    end

    test "contributors and strangers cannot take over", %{
      scheduling: scheduling,
      contributor: contributor,
      stranger: stranger
    } do
      scheduling = lose_organizer!(scheduling)

      for actor <- [contributor, stranger] do
        assert forbidden?(Podcasts.take_over_scheduling(scheduling, actor: actor))
      end

      # Without an actor there is nobody to relate as the Organizer.
      assert {:error, _} = Podcasts.take_over_scheduling(scheduling, actor: nil)
    end
  end
end
