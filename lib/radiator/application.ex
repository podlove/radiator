defmodule Radiator.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RadiatorWeb.Telemetry,
      Radiator.Repo,
      {DNSCluster, query: Application.get_env(:radiator, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:radiator, :ash_domains),
         Application.fetch_env!(:radiator, Oban)
       )},
      {Phoenix.PubSub, name: Radiator.PubSub},
      # Start a worker by calling: Radiator.Worker.start_link(arg)
      # {Radiator.Worker, arg},
      # Start to serve requests, typically the last entry
      RadiatorWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :radiator]}
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Radiator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RadiatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
