defmodule Radiator.Podcasts do
  @moduledoc false

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
    end

    resource Radiator.Podcasts.Episode do
      define :read_episodes, action: :read
      define :create_episode, action: :create
      define :get_episode_by_id, action: :read, get_by: :id
      define :update_episode, action: :update
      define :destroy_episode, action: :destroy
    end
  end
end
