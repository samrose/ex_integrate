defmodule ExIntegrate.Boundary.PipelineRunner do
  @moduledoc """
  Responsible for running steps and reporting their results.
  """
  use GenServer, restart: :temporary
  require Logger

  @task_supervisor ExIntegrate.TaskSupervisor

  alias ExIntegrate.Boundary.RunManager
  alias ExIntegrate.Boundary.StepRunner
  alias ExIntegrate.Core.Pipeline

  # Client API

  @spec start_link({Pipeline.t(), keyword(atom)}) :: GenServer.on_start()
  def start_link({%Pipeline{} = pipeline, opts}) when is_list(opts) do
    name = via(pipeline.name)
    GenServer.start_link(__MODULE__, {pipeline, opts}, name: name)
  end

  def via(key),
    do: {:via, Registry, {ExIntegrate.Registry.PipelineRunner, key}}

  @spec launch_pipeline(Pipeline.t()) :: DynamicSupervisor.on_start_child()
  def launch_pipeline(%Pipeline{} = pipeline) do
    DynamicSupervisor.start_child(
      ExIntegrate.Supervisor.PipelineRunner,
      {__MODULE__, {pipeline, []}}
    )
  end

  # GenServer callbacks

  @impl GenServer
  def init({pipeline, opts}) do
    initial_state = Pipeline.advance(pipeline)
    config = parse_opts(opts)

    {:ok, {initial_state, config}, {:continue, :run_step}}
  end

  defp parse_opts(opts) do
    default_config = [on_completion: &report_results/1]

    default_config
    |> Keyword.merge(opts)
    |> Keyword.take(Keyword.keys(default_config))
    |> Map.new()
  end

  @impl GenServer
  def handle_continue(:run_step, {state, config}) do
    current_step = Pipeline.current_step(state)
    Logger.info("Starting step: #{inspect(current_step)}")

    Task.Supervisor.async_nolink(@task_supervisor, fn ->
      StepRunner.run_step(current_step)
    end)

    {:noreply, {state, config}}
  end

  @impl GenServer
  def handle_info({ref, {:ok, step}}, {state, config}) do
    Logger.info("Step succeeded. #{inspect(step)}")
    Process.demonitor(ref, [:flush])

    state =
      state
      |> Pipeline.replace_current_step(step)
      |> Pipeline.advance()

    if Pipeline.complete?(state) do
      config.on_completion.(state)
      shut_down(state)
    else
      {:noreply, {state, config}, {:continue, :run_step}}
    end
  end

  @impl GenServer
  def handle_info({ref, {:error, step}}, {state, config}) do
    Logger.info("Step errored. #{inspect(step)}")
    Process.demonitor(ref, [:flush])

    state =
      state
      |> Pipeline.replace_current_step(step)
      |> Pipeline.advance()

    config.on_completion.(state)
    shut_down(state)
  end

  @impl GenServer
  def handle_info({:DOWN, ref, _, _, reason}, {state, config}) do
    Logger.error("Step task #{inspect(ref)} terminated unexpectedly. Reason: #{inspect(reason)}")
    config.on_completion.(state)
    shut_down(state)
  end

  defp report_results(state) do
    msg =
      if Pipeline.failed?(state) do
        "Pipeline failed. Terminating pipeline #{inspect(state)}"
      else
        "Pipeline succeeded. Terminating pipeline #{inspect(state)}"
      end

    Logger.info(msg)
    RunManager.pipeline_completed(state)
  end

  defp shut_down(state),
    do: {:stop, :normal, state}
end
