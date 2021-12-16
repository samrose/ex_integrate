defmodule ExIntegrate.Boundary.StepRunner do
  alias ExIntegrate.Core.Step

  @spec run_step(Step.t()) :: {:ok, Step.t()} | {:error, Step.t()}
  def run_step(%Step{} = step, opts \\ []) do
    command_path = System.find_executable(step.command)
    log = opts[:log] || true

    case Rambo.run(command_path, step.args, log: log) do
      {:ok, results} -> {:ok, save_results(step, results)}
      {:error, results} -> {:error, save_results(step, results)}
    end
  end

  defp save_results(step, %{status: status_code, out: out, err: err}),
    do: Step.save_results(step, status_code, out, err)
end
