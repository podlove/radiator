defmodule Radiator.MixProject do
  use Mix.Project

  def project do
    [
      app: :radiator,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Radiator.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:argon2_elixir, "~> 4.1"},
      {:beacon_live_admin, "~> 0.2"},
      {:beacon, "~> 0.2"},
      {:bandit, "~> 1.5"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.2"},
      {:ecto_sql, "~> 3.10"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:finch, "~> 0.13"},
      {:floki, ">= 0.30.0", override: true},
      {:gen_smtp, "~> 1.1"},
      {:gen_stage, "~> 1.2"},
      {:gettext, "~> 0.20"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "~> 1.2"},
      {:live_debugger, "~> 0.2.0", only: :dev},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_test_playwright, "~> 0.4", only: :test, runtime: false},
      {:phoenix, "~> 1.7.17"},
      {:plug, "~> 1.17"},
      {:postgrex, ">= 0.0.0"},
      {:reply, "~> 1.0"},
      {:req, "~> 0.5"},
      {:slugify, "~> 1.3"},
      {:swoosh, "~> 1.5"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:tidewave, "~> 0.1", only: :dev},
      {:timex, "~> 3.7"},
      {:web_inspector, git: "https://github.com/eteubert/web_inspector.git"},
      {:igniter, "~> 0.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build", "playwright.install"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind radiator", "esbuild radiator"],
      "assets.deploy": [
        "tailwind radiator --minify",
        "esbuild radiator --minify",
        "phx.digest"
      ],
      "playwright.install": [
        # "cmd npm ci --prefix assets",
        # "cmd cd assets",
        # "cmd npx playwright install-deps"
        # "cmd echo HALLO"

        # --prefix assets",
        # "cmd npm --prefix assets exec playwright install chromium firefox --with-deps"
        # "cmd npm --prefix assets exec playwright install firefox --with-deps"
      ]
    ]
  end
end
