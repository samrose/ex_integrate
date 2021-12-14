defmodule ExIntegrate.Boundary.PipelineRunner do
  @moduledoc """
  Responsible for running steps and reporting their results.
  """
  use GenServer

  @me __MODULE__
  @task_supervisor ExIntegrate.TaskSupervisor

  alias ExIntegrate.Boundary.StepRunner
  alias ExIntegrate.Core.Pipeline

  @spec run_pipeline(Pipeline.t()) :: Pipeline.t()
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

  def start_link({%Pipeline{} = state, config}) do
    GenServer.start_link(__MODULE__, {state, config}, name: @me)
  end

  def start_link(%Pipeline{} = pipeline, opts \\ []) do
    config = %{log: opts[:log] || true}
    start_link({pipeline, config})
  end

  @impl GenServer
  def init({%Pipeline{} = pipeline, config}) do
    {:ok, {pipeline, config}, {:continue, {:next_step}}}
  end

  @impl GenServer
  def handle_continue({:next_step}, {state, config}) do
    {next_step, new_state} = Pipeline.pop_step(state)

    Task.Supervisor.async_nolink(@task_supervisor, fn ->
      StepRunner.run_step(next_step, log: config.log)
    end)

    {:noreply, {new_state, config}}
  end

  @impl GenServer
  def handle_info({_ref, {:ok, step}}, {state, config}) do
    IO.puts("Step completed! #{inspect(step)}")
    {:noreply, {state, config}}
  end

  @impl GenServer
  def handle_info({_ref, {:error, step}}, {state, config}) do
    IO.puts("Step errored! #{inspect(step)}")
    {:stop, :step_failure, {state, config}}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, _, _, reason}, {state, config}) do
    IO.puts("Step task #{inspect(ref)} terminated. Reason: #{inspect(reason)}")
    {:noreply, {state, config}}
  end
end
