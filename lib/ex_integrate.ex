defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner
  alias ExIntegrate.Pipeline
  alias ExIntegrate.Config

  @spec run_pipelines(filename :: binary) :: {:ok, Config.t()}
  def run_pipelines(filename) when is_binary(filename) do
    %Config{} = config =
      import_json(filename)
      |> parse_config_params()

    Enum.each(config.pipelines, &Pipeline.run/1)

    {:ok, config}
  end

  defdelegate run_step(step), to: StepRunner

  defp import_json(filename) do
    config_json =
      filename
      |> File.read!()
      |> Jason.decode!()
  end

  defp parse_config_params(config_params) do
    pipelines =
      config_params
      |> Access.get("pipelines", [])
      |> Enum.map(fn pipeline_attrs ->
        steps = Enum.map(pipeline_attrs["steps"], &Step.new/1)
        %Pipeline{steps: steps}
      end)

    %Config{pipelines: pipelines}
  end
end
