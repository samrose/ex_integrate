defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Config
  alias ExIntegrate.Pipeline

  @spec run_pipelines_from_file(filename :: binary) :: {:ok, Config.t()}
  def run_pipelines_from_file(filename) do
    params = import_json(filename)
    run_pipelines(params)
  end

  @spec run_pipelines(map) :: {:ok, Config.t()}
  def run_pipelines(params) when is_map(params) do
    config = Config.new(params)
    Enum.each(config.pipelines, &Pipeline.run/1)

    {:ok, config}
  end

  defp import_json(filename) do
    filename
    |> File.read!()
    |> Jason.decode!()
  end
end
