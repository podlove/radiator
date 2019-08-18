use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :radiator, RadiatorWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :radiator, Radiator.Repo,
  username: "postgres",
  password: "postgres",
  database: "radiator_test",
  hostname: System.get_env("DB_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Speed up password hashing during test
config :argon2_elixir, t_cost: 1, m_cost: 8

config :arc,
  storage: Arc.Storage.S3,
  asset_host: System.get_env("STORAGE_ASSET_HOST", "http://localhost:9000"),
  bucket: "radiator-test"

config :ex_aws,
  access_key_id: "IEKAZMUY3KX32CRJPE9R",
  secret_access_key: "tXNYsfJyb8ctDgZSaIOYpndQwxOv8T+E+U0Rq3mN"

config :ex_aws, :s3,
  scheme: "http://",
  host: System.get_env("STORAGE_HOST") || "localhost",
  port: 9000

config :radiator, Radiator.Mailer, adapter: Radiator.Email.Console
