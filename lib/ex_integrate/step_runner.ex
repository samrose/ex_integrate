defmodule ExIntegrate.Boundary.Runner do
  @moduledoc """
  `Runner` is responsible for running steps and reporting their results.
  """

  alias __MODULE__
  alias ExIntegrate.Core.Step
  alias ExIntegrate.Core.Pipeline

  @spec run_pipeline(Pipeline.t()) :: Pipeline.t()
  def run_pipeline(%Pipeline{} = pipeline) do
    Enum.reduce(pipeline.steps, pipeline, fn step, acc ->
      case Runner.run_step(step) do
        {:ok, step} ->
          Pipeline.complete_step(acc, step)

        {:error, _error} ->
          acc
          |> Pipeline.complete_step(step)
          |> Pipeline.fail()
      end
    end)
  end

  @spec run_step(Step.t()) :: {:ok, Step.t()} | {:error, Step.t()}
  def run_step(%Step{} = step) do
    path = System.find_executable(step.command)

    case do_run_step(step, path) do
      {:ok, %{status: status_code, out: out, err: err}} ->
        {:ok, Step.save_results(step, status_code, out, err)}

      {:error, %{status: status_code, out: out, err: err}} ->
        {:error, Step.save_results(step, status_code, out, err)}
    end
  end

  defp do_run_step(step, path) do
    Rambo.run(path, step.args, log: true)
  end
end
