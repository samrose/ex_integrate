defmodule ExIntegrate.StepRunner do
  @moduledoc """
  `StepRunner` is responsible for running steps and reporting their results.
  """

  alias ExIntegrate.Step

  @spec run_step(Step.t()) :: {:ok, term} | {:error, term}
  def run_step(%Step{} = step) do
    path = System.find_executable(step.command)

    case do_run_step(step, path) do
      {:ok, %{status: status}} when status !== 0 ->
        {:error, %Step.Error{reason: :nonzero_status}}

      {:ok, result} ->
        {:ok, result}

      {:error, reason} ->
        {:error, %Step.Error{reason: :something, message: reason}}
    end
  end

  defp do_run_step(step, path) do
    Rambo.run(path, step.args, log: true)
  end
end
