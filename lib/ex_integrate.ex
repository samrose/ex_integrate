defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner
  alias ExIntegrate.Config

  @spec run_steps(filename :: binary) :: :ok
  def run_steps(filename) when is_binary(filename) do
    config = import_json(filename)
    steps = Enum.map(config.pipelines, fn(x)->
      Enum.map(x["steps"], &Step.new/1)
    end)
    |> List.flatten
    Enum.each(steps, &run_step/1)
    :ok
  end

  defdelegate run_step(step), to: StepRunner

  defp import_json(filename) do
    config_json =
      filename
      |> File.read!()
      |> Jason.decode!()

    %Config{pipelines: config_json["pipelines"]}
  end
end
