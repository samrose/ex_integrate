defmodule ExIntegrate.Boundary.PipelineRunner do
  @moduledoc """
  Responsible for running steps and reporting their results.
  """
  use GenServer
  require Logger

  @me __MODULE__
  @task_supervisor ExIntegrate.TaskSupervisor

  alias ExIntegrate.Boundary.StepRunner
  alias ExIntegrate.Core.Pipeline

  @spec start_link({Pipeline.t(), Access.t()}) :: {:ok, pid} | {:error, term} | :ignore
  def start_link({%Pipeline{} = state, opts}) do
    config = %{log: opts[:log] || true}
    GenServer.start_link(__MODULE__, {state, config}, name: @me)
  end

  def start_link(%Pipeline{} = pipeline, opts \\ []) do
    start_link({pipeline, opts})
  end

  @deprecated "Use PipelineRunner.start_link/1 instead."
  def run_pipeline(%Pipeline{} = pipeline) do
    Enum.reduce(pipeline.steps, pipeline, fn step, acc ->
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

  @impl GenServer
  def init({%Pipeline{} = pipeline, config}) do
    pipeline = Pipeline.advance(pipeline)
    {:ok, {pipeline, config}, {:continue, {:run_step}}}
  end

  @impl GenServer
  def handle_continue({:run_step}, {state, config}) do
    Task.Supervisor.async_nolink(@task_supervisor, fn ->
      current_step = Pipeline.current_step(state)
      StepRunner.run_step(current_step, log: config.log)
    end)

    {:noreply, {state, config}}
  end

  @impl GenServer
  def handle_info({_ref, {:ok, step}}, {state, config}) do
    Logger.info("Step completed! #{inspect(step)}")

    if Pipeline.complete?(state) do
      {:stop, :steps_complete, {state, config}}
    else
      new_state = Pipeline.advance(state)
      {:noreply, {new_state, config}, {:continue, {:run_step}}}
    end
  end

  @impl GenServer
  def handle_info({_ref, {:error, step}}, {state, config}) do
    Logger.info("Step errored! #{inspect(step)}")
    {:stop, :step_failure, {state, config}}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, _, _, reason}, {state, config}) do
    Logger.info("Step task #{inspect(ref)} terminated. Reason: #{inspect(reason)}")
    {:noreply, {state, config}}
  end
end


