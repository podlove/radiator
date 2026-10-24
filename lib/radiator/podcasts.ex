defmodule Radiator.Podcasts do
  @moduledoc """
  Podcasts, their episodes and the people credited on them.

  A podcast is either maintained by hand or imported from a feed and kept in
  sync with it. The sync machinery — the `:sync`, `:apply_feed` and
  `:mark_sync_failed` actions on `Podcast` — is driven by Oban and has no code
  interface on purpose; `import_podcast/2` and `request_sync/1` are the ways in.
  """

  use Ash.Domain, otp_app: :radiator, extensions: [AshPhoenix, AshAdmin.Domain, AshJsonApi.Domain]

  json_api do
    routes do
      base_route "/podcasts", Radiator.Podcasts.Podcast do
        index :read
        get :read
        post :create
        patch :update
        delete :destroy
      end
    end
  end

  admin do
    show? true
  end

  resources do
    resource Radiator.Podcasts.Podcast do
      define :create_podcast, action: :create
      define :import_podcast, action: :import
      define :read_podcasts, action: :read
      define :get_podcast_by_id, action: :read, get_by: :id
      define :update_podcast, action: :update
      define :destroy_podcast, action: :destroy
      define :request_sync, action: :request_sync
      define :public_read_podcasts, action: :public_read
      define :public_get_podcast_by_id, action: :public_read, get_by: :id
    end

    # Managed through the podcast's `:update` action.
    resource Radiator.Podcasts.PodcastUserRole

    resource Radiator.Podcasts.Episode do
      define :read_episodes, action: :read
      define :create_episode, action: :create
      define :get_episode_by_id, action: :read, get_by: :id
      define :update_episode, action: :update
      define :destroy_episode, action: :destroy
    end

    # Written mostly by the feed sync, which uses the resources' bulk actions
    # directly.
    resource Radiator.Podcasts.Person do
      define :read_podcast_contributors, action: :contributed_to_podcast, args: [:podcast_id]
      define :read_scheduling_participants, action: :scheduling_participants, args: [:episode_id]
    end

    resource Radiator.Podcasts.EpisodeContributor

    resource Radiator.Podcasts.Episode.Scheduling do
      define :start_scheduling, action: :start, args: [:episode_id, :proposed_datetimes]
      define :get_scheduling_by_episode, action: :by_episode, args: [:episode_id]
      define :add_scheduling_proposal, action: :add_proposal, args: [:datetime]
      define :remove_scheduling_proposal, action: :remove_proposal, args: [:proposal_id]
      define :vote_on_proposal, action: :vote, args: [:proposal_id, :score]
      define :remove_vote, action: :remove_vote, args: [:proposal_id]
      define :finalize_scheduling, action: :finalize, args: [:chosen_proposal_id]
      define :reopen_scheduling, action: :reopen
    end
  end
end
