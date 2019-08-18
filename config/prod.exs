use Mix.Config

config :radiator, RadiatorWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, level: :info

config :radiator, Radiator.Repo, pool_size: 10
