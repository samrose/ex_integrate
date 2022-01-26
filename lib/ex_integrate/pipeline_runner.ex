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

  @spec start_link(Access.t()) :: {:ok, pid} | {:error, term} | :ignore
  def start_link(opts) do
    name = opts[:name] || @me
    GenServer.start_link(__MODULE__, opts, name: name)
  end

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
    Task.Supervisor.async_nolink(@task_supervisor, fn ->
      current_step = Pipeline.current_step(state)
      Logger.info("Starting step: #{inspect(current_step)}")
      StepRunner.run_step(current_step, log: config.log)
    end)

    {:noreply, {state, config}}
  end

  @impl GenServer
  def handle_info({ref, {:ok, step}}, {state, config}) do
    Logger.info("Step completed. #{inspect(step)}")
    Process.demonitor(ref, [:flush])

    new_state =
      state
      |> Pipeline.replace_current_step(step)
      |> Pipeline.advance()

    if Pipeline.complete?(new_state) do
      Logger.info("All steps completed successfully. Terminating pipeline #{inspect(new_state)}")

      RunManager.pipeline_completed(new_state)

      {:stop, :normal, {new_state, config}}
    else
      {:noreply, {new_state, config}, {:continue, {:run_step}}}
    end
  end

  @impl GenServer
  def handle_info({_ref, {:error, step}}, {state, _config}) do
    Logger.info("Step errored. #{inspect(step)}")
    {:stop, :step_failure, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, _, _, reason}, {state, _config}) do
    Logger.info("Step task #{inspect(ref)} terminated unexpectedly. Reason: #{inspect(reason)}")
    {:stop, :step_failure, state}
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
      case StepRunner.run_step(step) do
        {:ok, step} ->
          Pipeline.complete_step(acc, step)

        {:error, _error} ->
          acc
          |> Pipeline.complete_step(step)
          |> Pipeline.fail()
      end
    end)
  end
end
