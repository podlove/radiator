import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :argon2_elixir, t_cost: 1, m_cost: 8

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :radiator, Radiator.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "radiator_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :radiator, RadiatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "IR/sJ/Eum00VCgDtlIPWommlT4nig7Q51n5FnE1kdjaf1lhin4JGGB1RsanOPgfT",
  server: true

# In test we don't send emails
config :radiator, Radiator.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Enable tree consistency validator: crashes when tree is not valid!
config :radiator, tree_consistency_validator: true

config :phoenix_test,
  endpoint: RadiatorWeb.Endpoint,
  otp_app: :radiator,
  playwright: [
    browser: :chromium,
    headless: System.get_env("PLAYWRIGHT_HEADLESS", "t") in ~w(t true),
    trace: System.get_env("PLAYWRIGHT_TRACE", "false") in ~w(t true)
  ]
