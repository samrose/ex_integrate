defmodule ExIntegrate.Boundary.Server do
  @moduledoc """
  The primary long-lived server, responsible for kicking off `RunManager`s.
  """
  use GenServer

  alias ExIntegrate.Boundary.RunManager
  alias ExIntegrate.Core.Run

  @server __MODULE__
  def start_link(opts) do
    name = opts[:name] || @server
    GenServer.start_link(__MODULE__, :no_arg, name: name)
  end

  @spec run(GenServer.name(), Run.t()) :: {:ok, Run.t()} | {:error, Run.t()}
  def run(server \\ @server, run),
    do: GenServer.call(server, {:run, run})

  @impl GenServer
  def init(_),
    do: {:ok, nil}

  @impl GenServer
  def handle_call({:run, run}, _from, state) do
    {:reply, RunManager.run(run), state}
  end
end
