[
  import_deps: [
    :ash_oban,
    :oban,
    :ash_state_machine,
    :ash_authentication,
    :ash_authentication_phoenix,
    :ash_admin,
    :ash_phoenix,
    :ash_postgres,
    :ash,
    :reactor,
    :ecto,
    :ecto_sql,
    :phoenix
  ],
  subdirectories: ["priv/*/migrations"],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
