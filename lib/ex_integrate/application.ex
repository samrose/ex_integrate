defmodule ExIntegrate.Application do
  @moduledoc false

  require Logger
  use Application

  @impl Application
  def start(_type, _args) do
    Logger.info("Starting ExIntegrate")

    children = [
      {Task.Supervisor, name: ExIntegrate.TaskSupervisor},
      {Registry, name: ExIntegrate.Registry.PipelineRunner, keys: :unique},
      {DynamicSupervisor, name: ExIntegrate.Supervisor.PipelineRunner, strategy: :one_for_one},
      {ExIntegrate.Boundary.RunManager, [name: ExIntegrate.Boundary.RunManager]},
      {ExIntegrate, [name: ExIntegrate]}
    ]

    opts = [strategy: :one_for_one, name: ExIntegrate.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
