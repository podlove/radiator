# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

default_host = "localhost"
default_host = "darthdom.local"

config :radiator,
  ecto_repos: [Radiator.Repo]

# Configures the endpoint
config :radiator, RadiatorWeb.Endpoint,
  url: [host: default_host],
  secret_key_base: "Ulfk2ILpLFu95vdZSe8Af8pjN9n516jHZXb7BUnPHU0xu8g/tyAdNzZBVGtMo0JH",
  render_errors: [view: RadiatorWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Radiator.PubSub, adapter: Phoenix.PubSub.PG2]

config :radiator, Radiator.Auth.Guardian,
  issuer: "radiator",
  secret_key: "dev-only;I1B6O0dEt9sBw6531zH/vDHKEDTY64ohsPxLw5jvLtKaphKofVC/NM5nzkbyD4HW"

config :radiator,
  storage_bucket: "radiator"

config :radiator, :auth,
  email_from_name: "Radiator-Instance",
  email_from_email: "do_not_reply@radiator.local"

config :radiator, Radiator.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp.domain",
  hostname: "your.domain",
  port: 1025,
  # or {:system, "SMTP_USERNAME"}
  username: "your.name@your.domain",
  # or {:system, "SMTP_PASSWORD"}
  password: "pa55word",
  # can be `:always` or `:never`
  tls: :if_available,
  # or {":system", ALLOWED_TLS_VERSIONS"} w/ comma seprated values (e.g. "tlsv1.1,tlsv1.2")
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  # can be `true`
  ssl: false,
  retries: 1,
  # can be `true`
  no_mx_lookups: false,
  # can be `always`. If your smtp relay requires authentication set it to `always`.
  auth: :if_available

config :arc,
  # or Arc.Storage.Local
  storage: Arc.Storage.S3,
  # if using Amazon S3
  bucket: "radiator",
  asset_host: System.get_env("STORAGE_ASSET_HOST") || "http://#{default_host}:9000/radiator"

config :ex_aws,
  access_key_id: "IEKAZMUY3KX32CRJPE9R",
  secret_access_key: "tXNYsfJyb8ctDgZSaIOYpndQwxOv8T+E+U0Rq3mN",
  json_codec: Jason

config :ex_aws, :s3,
  scheme: "http://",
  host: System.get_env("STORAGE_HOST") || default_host,
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

config :ex_aws,
  access_key_id: "9Q6BJW3959KUSF70H3AT",
  secret_access_key: "DebokMib7cSHHtfc3zHQoDLZ4uXXQmNGXdI6qVe+",
  json_codec: Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
