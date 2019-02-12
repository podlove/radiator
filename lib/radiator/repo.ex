defmodule Radiator.Repo do
  use Ecto.Repo,
    otp_app: :radiator,
    adapter: Ecto.Adapters.Postgres
end
