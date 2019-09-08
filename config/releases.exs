import Config

config :radiator, RadiatorWeb.Endpoint,
  http: [:inet6, port: System.fetch_env!("PORT")],
  url: [host: System.fetch_env!("HOST"), port: System.fetch_env!("PUBLIC_PORT")]

config :radiator, Radiator.Repo,
  username: System.fetch_env!("POSTGRES_USER"),
  password: System.fetch_env!("POSTGRES_PASSWORD"),
  database: System.fetch_env!("POSTGRES_DATABASE"),
  hostname: System.fetch_env!("POSTGRES_HOST")

config :arc,
  asset_host: System.fetch_env!("STORAGE_ASSET_HOST")

config :ex_aws,
  access_key_id: System.fetch_env!("STORAGE_ACCESS_KEY_ID"),
  secret_access_key: System.fetch_env!("STORAGE_ACCESS_KEY")

config :ex_aws, :s3,
  scheme: "http://",
  host: System.fetch_env!("STORAGE_HOST"),
  port: System.fetch_env!("STORAGE_PORT")

config :radiator, Radiator.Mailer,
  server: System.fetch_env!("SMTP_SERVER"),
  hostname: System.fetch_env!("SMTP_HOSTNAME"),
  port: System.fetch_env!("SMTP_PORT"),
  username: System.fetch_env!("SMTP_USERNAME"),
  password: System.fetch_env!("SMTP_PASSWORD")
