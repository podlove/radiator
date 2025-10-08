defmodule Radiator.Podcasts do
  use Ash.Domain, otp_app: :radiator, extensions: [AshPhoenix, AshAdmin.Domain]

  forms do
    form :create_episode, args: [:show_id]
  end

  admin do
    show? true
  end

  resources do
    resource Radiator.Podcasts.Show do
      define :create_show, action: :create
      define :read_shows, action: :read
      define :get_show_by_id, action: :read, get_by: :id
      define :update_show, action: :update
      define :destroy_show, action: :destroy
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
