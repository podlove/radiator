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
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
