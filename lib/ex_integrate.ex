defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner

  @spec run_steps(filename :: binary) :: :ok
  def run_steps(filename) when is_binary(filename) do
    config =
      filename
      |> File.read!()
      |> Jason.decode!()

    steps = Enum.map(config["steps"], &Step.new/1)
    Enum.each(steps, &run_step/1)
    :ok
  end

  defdelegate run_step(step), to: StepRunner
end
