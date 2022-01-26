defmodule ExIntegrate.Boundary.RunManager do
  use GenServer, restart: :permanent
  require Logger

  alias ExIntegrate.Boundary.PipelineRunner
  alias ExIntegrate.Core.Run
  alias ExIntegrate.Core.Pipeline

  @server RunManager

  # API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @server)
  end

  def start_run(server \\ @server, %Run{} = run),
    do: GenServer.call(server, {:start_run, run})

  def pipeline_completed(server \\ @server, %Pipeline{} = pipeline),
    do: GenServer.call(server, {:pipeline_completed, pipeline})

  # GenServer Implementation

  @impl GenServer
  def init(_) do
    {:ok, nil}
  end

  def handle_continue({:start_next_pipelines, _current_pipeline}, {state, 0}) do
    Logger.info("Run completed")
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_continue({:start_next_pipelines, current_pipeline}, {state, count}) do
    state
    |> Run.next_pipelines(current_pipeline)
    |> Enum.each(&PipelineRunner.launch_pipeline/1)

    {:noreply, {state, count}}
  end

  # Starting a run:
  # Set up initial state and count
  @impl GenServer
  def handle_call({:start_run, run}, _from, nil = _state) do
    current_pipeline = Run.pipeline_root(run)
    count = run.end_nodes
    {:reply, :ok, {run, count}, {:continue, {:start_next_pipelines, current_pipeline}}}
  end

  def handle_call({:start_run, _run}, _from, state) do
    {:reply, {:error, :already_running}, state}
  end

  def handle_call({:pipeline_completed, %Pipeline{} = pipeline}, _from, {state, count}) do
    new_state = Run.put_pipeline(state, pipeline.name, pipeline)
    new_count = maybe_dec_count(count, new_state, pipeline)

    {:reply, :ok, {new_state, new_count}, {:continue, {:start_next_pipelines, pipeline}}}
  end

  defp maybe_dec_count(count, run, pipeline) do
    if pipeline in Run.final_pipelines(run) do
      count - 1
    else
      count
    end
  end
end
