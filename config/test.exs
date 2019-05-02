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
