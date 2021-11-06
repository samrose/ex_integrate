defmodule ExIntegrate.StepRunner do
  @moduledoc """
  `StepRunner` is responsible for running steps and reporting their results.
  """

  alias ExIntegrate.Step

  @spec run_step(Step.t()) :: {:ok, Step.t()} | {:error, Step.Error.t()}
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
