defmodule Radiator.Podcasts do
  @moduledoc """
  Podcasts, their episodes and the people credited on them.

  A podcast is either maintained by hand or imported from a feed and kept in
  sync with it. The sync machinery — the `:sync`, `:apply_feed` and
  `:mark_sync_failed` actions on `Podcast` — is driven by Oban and has no code
  interface on purpose; `import_podcast/2` and `request_sync/1` are the ways in.
  """

  use Ash.Domain, otp_app: :radiator, extensions: [AshPhoenix, AshAdmin.Domain]

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

    # Written only by the feed sync, which uses the resources' bulk actions
    # directly; there is no code interface until a caller needs one.
    resource Radiator.Podcasts.Person
    resource Radiator.Podcasts.EpisodeContributor
  end
end
