use Mix.Config

default_host = System.get_env("DEFAULT_HOST", "localhost")

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :radiator, RadiatorWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      "--color",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :arc,
  asset_host: System.get_env("STORAGE_ASSET_HOST", "http://#{default_host}:9000/radiator")

config :ex_aws,
  access_key_id: System.get_env("STORAGE_ACCESS_KEY_ID", "IEKAZMUY3KX32CRJPE9R"),
  secret_access_key:
    System.get_env("STORAGE_ACCESS_KEY", "tXNYsfJyb8ctDgZSaIOYpndQwxOv8T+E+U0Rq3mN")

config :ex_aws, :s3,
  scheme: "http://",
  host: System.get_env("STORAGE_HOST", default_host),
  port: System.get_env("STORAGE_PORT", "9000")

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :radiator, RadiatorWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/radiator_web/views/.*(ex)$},
      ~r{lib/radiator_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Configure your database
config :radiator, Radiator.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: "radiator_dev",
  hostname: System.get_env("POSTGRES_HOST", default_host),
  pool_size: 10

config :radiator, Radiator.Mailer, adapter: Radiator.Email.Console

config :radiator, :sandbox_mode, enabled: System.get_env("SANDBOX_MODE_ENABLED", "true")

config :radiator, Radiator.Scheduler, global: false
