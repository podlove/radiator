use Mix.Config

default_host = System.get_env("DEFAULT_HOST", "localhost")

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :radiator, RadiatorWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :radiator, Radiator.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: "radiator_test",
  hostname: System.get_env("POSTGRES_HOST", System.get_env("DB_HOST", default_host)),
  pool: Ecto.Adapters.SQL.Sandbox

# Speed up password hashing during test
config :argon2_elixir, t_cost: 1, m_cost: 8

config :arc,
  storage: Arc.Storage.S3,
  asset_host: System.get_env("STORAGE_ASSET_HOST", "http://#{default_host}:9000"),
  bucket: "radiator-test"

config :ex_aws,
  access_key_id: System.get_env("STORAGE_ACCESS_KEY_ID", "IEKAZMUY3KX32CRJPE9R"),
  secret_access_key:
    System.get_env("STORAGE_ACCESS_KEY", "tXNYsfJyb8ctDgZSaIOYpndQwxOv8T+E+U0Rq3mN")

config :ex_aws, :s3,
  scheme: "http://",
  host: System.get_env("STORAGE_HOST", default_host),
  port: 9000

config :radiator, Radiator.Mailer, adapter: Radiator.Email.Console

config :radiator, Oban, queues: false, prune: :disabled
