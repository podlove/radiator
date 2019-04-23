defmodule Radiator.Repo do
  use Radiator.Constants

  use Ecto.Repo,
    otp_app: @otp_app,
    adapter: Ecto.Adapters.Postgres
end
