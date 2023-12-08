defmodule Fortymm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FortymmWeb.Telemetry,
      Fortymm.Repo,
      {DNSCluster, query: Application.get_env(:fortymm, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Fortymm.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Fortymm.Finch},
      # Start a worker by calling: Fortymm.Worker.start_link(arg)
      # {Fortymm.Worker, arg},
      # Start to serve requests, typically the last entry
      FortymmWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fortymm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FortymmWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
