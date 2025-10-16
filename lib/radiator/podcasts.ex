defmodule Radiator.Podcasts do
  @moduledoc false

  use Ash.Domain, otp_app: :radiator, extensions: [AshPhoenix, AshAdmin.Domain]

  forms do
    form :create_episode, args: [:podcast_id]
  end

  admin do
    show? true
  end

  resources do
    resource Radiator.Podcasts.Podcast do
      define :create_podcast, action: :create
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
    end

    resource Radiator.Podcasts.Chapter
    resource Radiator.Podcasts.License
  end
end
