defmodule Radiator.Podcasts do
  use Ash.Domain,
    otp_app: :radiator

  resources do
    resource Radiator.Podcasts.Show
    resource Radiator.Podcasts.Episode
  end
end
