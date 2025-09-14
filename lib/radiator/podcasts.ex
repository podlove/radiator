defmodule Radiator.Podcasts do
  use Ash.Domain, otp_app: :radiator, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Radiator.Podcasts.Show
    resource Radiator.Podcasts.Episode
    resource Radiator.Podcasts.Chapter
    resource Radiator.Podcasts.License
  end
end
