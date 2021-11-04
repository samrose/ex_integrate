defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Config
  alias ExIntegrate.Pipeline
  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner

  @spec run_pipelines(filename :: binary) :: {:ok, Config.t()}
  def run_pipelines(filename) when is_binary(filename) do
    params = import_json(filename)
    %Config{} = config = parse_config_params(params)

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

  defp parse_config_params(params) do
    Config.new(params)
  end
end
