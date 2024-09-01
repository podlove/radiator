defmodule Radiator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Radiator.Outline.CommandProcessor
  alias Radiator.Outline.CommandQueue
  alias Radiator.Outline.NodeChangeListener

  @impl true
  def start(_type, _args) do
    job_runner_config = [
      strategy: :one_for_one,
      max_seconds: 30,
      name: Radiator.JobRunner
    ]

    children = [
      RadiatorWeb.Telemetry,
      Radiator.Repo,
      {DNSCluster, query: Application.get_env(:radiator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Radiator.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Radiator.Finch},
      # Start a worker by calling: Radiator.Worker.start_link(arg)
      # {Radiator.Worker, arg},
      # Start to serve requests, typically the last entry
      RadiatorWeb.Endpoint,
      {CommandQueue, name: CommandQueue},
      {CommandProcessor, name: CommandProcessor, subscribe_to: [{CommandQueue, max_demand: 1}]},
      {NodeChangeListener, name: NodeChangeListener},
      {Registry, keys: :unique, name: Radiator.JobRegistry},
      {DynamicSupervisor, job_runner_config}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
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
