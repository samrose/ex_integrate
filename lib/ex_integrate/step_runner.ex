defmodule ExIntegrate.StepRunner do
  @moduledoc """
  `StepRunner` is responsible for running steps and reporting their results.
  """

  alias ExIntegrate.Step

  @spec run_step(Step.t()) :: {:ok, Step.t()} | {:error, Step.Error.t()}
  def run_step(%Step{} = step) do
    path = System.find_executable(step.command)

    case do_run_step(step, path) do
      {:ok, %{status: status_code}} when status_code !== 0 ->
        {:error, %Step.Error{reason: :nonzero_status}}

      {:ok, %{status: status_code, out: out, err: err}} ->
        {:ok, %{step | status_code: status_code, out: out, err: err}}

      {:error, reason} ->
        {:error, %Step.Error{reason: :unknown, message: reason}}
    end
  end

  defp do_run_step(step, path) do
    Rambo.run(path, step.args, log: true)
  end
end
