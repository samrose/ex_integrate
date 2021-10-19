defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner

  def run_steps(filename) when is_binary(filename) do
    config_json =
      filename
      |> File.read!()
      |> Jason.decode!()

    steps = Enum.map(config_json["steps"], &Step.new/1)

    Enum.each(steps, &run_step/1)
  end

  defdelegate run_step(step), to: StepRunner
end
