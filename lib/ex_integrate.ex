defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner
  alias ExIntegrate.Config

  @spec run_pipelines(filename :: binary) :: :ok
  def run_pipelines(filename) when is_binary(filename) do
    config = import_json(filename)

    Enum.map(config.pipelines, fn x ->
      steps = Enum.map(x["steps"], &Step.new/1)

      pipeline_task =
        Task.async(fn ->
          Enum.each(steps, &run_step/1)
        end)

      Task.await(pipeline_task)
    end)

    {:ok, config}
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
