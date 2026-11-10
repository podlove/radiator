defmodule Radiator.Podcasts.Episode.Scheduling.Policies do
  @moduledoc """
  Who may do what with an episode's scheduling (ADR 0001, ADR 0002).

  Members of the podcast start a scheduling and propose dates. The Organizer
  (the Member who started or took it over) decides: they finalize, reopen,
  delete and remove any proposal, but only while still a Member. Participants
  (the episode's contributors with an account) vote and propose dates; that
  everybody but the Organizer removes only their own proposals is checked by
  `OrganizerOrProposalCreator`. When the Organizer is gone, any Member may
  take over (`OrganizerGone`). Everybody else sees nothing.
  """

  use Spark.Dsl.Fragment, of: Ash.Resource, authorizers: [Ash.Policy.Authorizer]

  alias Radiator.Podcasts.Episode.Scheduling.Checks

  policies do
    policy action_type(:read) do
      authorize_if Checks.PodcastMember
      authorize_if Checks.Participant
    end

    policy action(:start) do
      authorize_if Checks.MemberOfNewEpisode
    end

    policy action([:add_proposal, :remove_proposal]) do
      authorize_if Checks.PodcastMember
      authorize_if Checks.Participant
    end

    policy action([:vote, :remove_vote]) do
      authorize_if Checks.Participant
    end

    policy action([:finalize, :reopen, :destroy]) do
      authorize_if Checks.Organizer
    end

    policy action(:take_over) do
      authorize_if Checks.PodcastMember
    end
  end
end
