# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :radiator,
  ecto_repos: [Radiator.Repo, Radiator.Auth.Repo]

# Configures the endpoint
config :radiator, RadiatorWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Ulfk2ILpLFu95vdZSe8Af8pjN9n516jHZXb7BUnPHU0xu8g/tyAdNzZBVGtMo0JH",
  render_errors: [view: RadiatorWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Radiator.PubSub, adapter: Phoenix.PubSub.PG2]

config :radiator, Radiator.Auth.Guardian,
  issuer: "radiator",
  secret_key: "dev-only;I1B6O0dEt9sBw6531zH/vDHKEDTY64ohsPxLw5jvLtKaphKofVC/NM5nzkbyD4HW"

config :radiator,
  storage_bucket: "radiator"

config :ex_aws,
  access_key_id: "IEKAZMUY3KX32CRJPE9R",
  secret_access_key: "tXNYsfJyb8ctDgZSaIOYpndQwxOv8T+E+U0Rq3mN",
  json_codec: Jason

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

config :ex_aws, :hackney_opts,
  follow_redirect: true,
  recv_timeout: 30_000

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
