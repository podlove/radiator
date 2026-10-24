defmodule Radiator.Podcasts.Episode.Scheduling.Policies do
  @moduledoc """
  Who may do what with an episode's scheduling (ADR 0001, spec 04).

  Members of the podcast decide: they start the scheduling, manage every
  proposal, pick the date and reopen. The episode's contributors with an
  account vote and propose dates; that a contributor removes only their own
  proposals is checked by `MemberOrProposalCreator`. Everybody else sees
  nothing.
  """

  use Spark.Dsl.Fragment, of: Ash.Resource, authorizers: [Ash.Policy.Authorizer]

  alias Radiator.Podcasts.Episode.Scheduling.Checks

  policies do
    policy action_type(:read) do
      authorize_if Checks.PodcastMember
      authorize_if Checks.EpisodeContributor
    end

    policy action(:start) do
      authorize_if Checks.MemberOfNewEpisode
    end

    policy action([:add_proposal, :remove_proposal]) do
      authorize_if Checks.PodcastMember
      authorize_if Checks.EpisodeContributor
    end

    policy action([:vote, :remove_vote]) do
      authorize_if Checks.EpisodeContributor
    end

    policy action([:finalize, :reopen, :destroy]) do
      authorize_if Checks.PodcastMember
    end
  end
end
