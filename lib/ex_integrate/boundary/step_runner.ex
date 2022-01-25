defmodule ExIntegrate.Boundary.StepRunner do
  @moduledoc """
  Responsible for running `Step`s, the primary units of CI work. See `Step` docs
  for more information.

  Note that for now, running a step always consists of determing its system
  executable and making an external system call via `Rambo`. In the future,
  for testing purposes, it may be desirable to add a mock implementation that
  avoids the external system call. 
  """
  require Logger
  alias ExIntegrate.Core.Step

  @spec run_step(Step.t(), Access.t()) :: {:ok, Step.t()} | {:error, Step.t()}
  def run_step(%Step{} = step, opts \\ []) do
    # credo:disable-for-next-line
    # TODO: handle cases where no executable can be found
    command_path = System.find_executable(step.command)
    log_command_output = opts[:log] || (&log_command_output(&1, command_path))

    case Rambo.run(command_path, step.args, log: log_command_output) do
      {:ok, results} -> {:ok, save_results(step, results)}
      {:error, results} -> {:error, save_results(step, results)}
    end
  end

  defp save_results(step, %{status: status_code, out: out, err: err}),
    do: Step.save_results(step, status_code, out, err)

  defp log_command_output({stdout_or_err, output}, command_path) do
    Logger.info("""
    Received system command output.
    Command: #{command_path}
    Source: #{stdout_or_err}
    Output: #{output}
    """)
  end
end
