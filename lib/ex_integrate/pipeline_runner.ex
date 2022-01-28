defmodule ExIntegrate.Boundary.PipelineRunner do
  @moduledoc """
  Responsible for running steps and reporting their results.
  """
  use GenServer, restart: :temporary
  require Logger

  @me __MODULE__
  @task_supervisor ExIntegrate.TaskSupervisor

  alias ExIntegrate.Boundary.RunManager
  alias ExIntegrate.Boundary.StepRunner
  alias ExIntegrate.Core.Pipeline

  # Client API

  def start_link(%Pipeline{} = pipeline) do
    name = {:via, Registry, {ExIntegrate.Registry.PipelineRunner, pipeline}}
    GenServer.start_link(__MODULE__, [pipeline: pipeline], name: name)
  end

  @spec start_link(Access.t()) :: GenServer.on_start_child()
  def start_link(opts) do
    name = opts[:name] || @me
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec launch_pipeline(Pipeline.t()) :: DynamicSupervisor.on_start_child()
  def launch_pipeline(%Pipeline{} = pipeline) do
    DynamicSupervisor.start_child(
      ExIntegrate.Supervisor.PipelineRunner,
      {__MODULE__, pipeline}
    )
  end

  # GenServer callbacks

  @impl GenServer
  def init(opts) do
    initial_state = Access.fetch!(opts, :pipeline) |> Pipeline.advance()

    log = opts[:log] || true
    config = %{log: log}

    {:ok, {initial_state, config}, {:continue, {:run_step}}}
  end

  @impl GenServer
  def handle_continue({:run_step}, {state, config}) do
    current_step = Pipeline.current_step(state)
    Logger.info("Starting step: #{inspect(current_step)}")

    Task.Supervisor.async_nolink(@task_supervisor, fn ->
      StepRunner.run_step(current_step, log: config.log)
    end)

    {:noreply, {state, config}}
  end

  @impl GenServer
  def handle_info({ref, {:ok, step}}, {state, config}) do
    Logger.info("Step completed. #{inspect(step)}")
    Process.demonitor(ref, [:flush])

    state =
      state
      |> Pipeline.replace_current_step(step)
      |> Pipeline.advance()

    if Pipeline.complete?(state) do
      msg = "All steps completed successfully. Terminating pipeline #{inspect(state)}"
      finish_pipeline(state, msg)
    else
      {:noreply, {state, config}, {:continue, {:run_step}}}
    end
  end

  @impl GenServer
  def handle_info({ref, {:error, step}}, {state, _config}) do
    Logger.info("Step errored. #{inspect(step)}")
    Process.demonitor(ref, [:flush])

    state =
      state
      |> Pipeline.replace_current_step(step)
      |> Pipeline.advance()

    msg = "Step failure. Terminating pipeline #{inspect(state)}"
    finish_pipeline(state, msg)
  end

  @impl GenServer
  def handle_info({:DOWN, ref, _, _, reason}, {state, config}) do
    RunManager.pipeline_completed(state)
    Logger.info("Step task #{inspect(ref)} terminated unexpectedly. Reason: #{inspect(reason)}")
    {:stop, :normal, {state, config}}
  end

  defp finish_pipeline(state, msg) do
    RunManager.pipeline_completed(state)
    Logger.info(msg)

    {:stop, :normal, state}
  end

  @doc deprecated: """
       It runs pipelines using an old, naive, sequential implementation. Use
       #{__MODULE__}.start_link/1 instead for the recommended concurrent
       implementation.
       """
  def run_pipeline(%Pipeline{} = pipeline) do
    pipeline
    |> Pipeline.steps()
    |> Enum.reduce(pipeline, fn step, acc ->
      with {_ok_or_error, completed_step} <- StepRunner.run_step(step) do
        Pipeline.put_step(acc, step, completed_step)
      end
    end)
  end
end
