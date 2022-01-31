defmodule ExIntegrate.Boundary.RunManager do
  @moduledoc """
  Kicks off a run and returns the result as an `{:ok, run}` or `{:error, run}`
  tuple.
  """

  use GenServer, restart: :permanent
  require Logger

  alias ExIntegrate.Boundary.PipelineRunner
  alias ExIntegrate.Core.Run
  alias ExIntegrate.Core.Pipeline

  @server RunManager

  # API

  def start_link(_),
    do: GenServer.start_link(__MODULE__, nil, name: @server)

  def start_run(server \\ @server, %Run{} = run) do
    GenServer.call(server, {:start_run, run})
  end

  def pipeline_completed(server \\ @server, %Pipeline{} = pipeline),
    do: GenServer.call(server, {:pipeline_completed, pipeline})

  # GenServer Implementation

  @impl GenServer
  def init(_) do
    {:ok, nil}
  end

  def handle_continue({:start_next_pipelines, _current_pipeline}, {%{count: 0} = run, from}) do
    Logger.info("Run completed")

    ok_or_error = if Run.failed?(run), do: :error, else: :ok

    GenServer.reply(from, {ok_or_error, run})
    {:noreply, nil}
  end

  @impl GenServer
  def handle_continue({:start_next_pipelines, current_pipeline}, {run, from}) do
    if Run.failed?(run) do
      # don't launch any more pipeline runners

      {:noreply, {run, from}}
    else
      # continue launching pipeline runners
      run
      |> Run.next_pipelines(current_pipeline)
      |> Enum.each(&PipelineRunner.launch_pipeline/1)

      {:noreply, {run, from}}
    end
  end

  # Starting a run:
  # Set up initial state and kick off the run
  # Do not reply yet, as the run hasn't been completed yet
  @impl GenServer
  def handle_call({:start_run, run}, from, nil = _run) do
    current_pipeline = Run.pipeline_root(run)
    {:noreply, {run, from}, {:continue, {:start_next_pipelines, current_pipeline}}}

    # {:reply, :ok, {run, from}, {:continue, {:start_next_pipelines, current_pipeline}}}
  end

  # If state is not `nil`, then the run is already running
  def handle_call({:start_run, _run}, _from, {run, from}) do
    {:reply, {:error, :already_running}, {run, from}}
  end

  def handle_call({:pipeline_completed, %Pipeline{} = pipeline}, _from, {run, from}) do
    run =
      run
      |> Run.put_pipeline(pipeline.name, pipeline)
      |> Run.check_final_pipeline(pipeline)

    {:reply, :ok, {run, from}, {:continue, {:start_next_pipelines, pipeline}}}
  end
end
