defmodule Radiator.Podcasts do
  use Ash.Domain, otp_app: :radiator, extensions: [AshPhoenix, AshAdmin.Domain]

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

    resource Radiator.Podcasts.Episode
    resource Radiator.Podcasts.Chapter
    resource Radiator.Podcasts.License
  end
end
