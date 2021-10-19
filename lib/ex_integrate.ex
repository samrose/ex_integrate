defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Step

  def run_steps(filename) when is_binary(filename) do
    config_json =
      filename
      |> File.read!()
      |> Jason.decode!()

    steps = Enum.map(config_json["steps"], &Step.new/1)

    Enum.each(steps, &run_step/1)
  end

  def run_step(%Step{} = step) do
    path = System.find_executable(step.command)
    Rambo.run(path, step.args, log: true)
  end
end
