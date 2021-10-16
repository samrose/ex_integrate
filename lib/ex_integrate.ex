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

    Enum.each(steps, fn step ->
      path = System.find_executable(step.command)
      Rambo.run(path, step.args, log: true)
    end)
  end
end
