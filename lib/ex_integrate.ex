defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Boundary.Runner
  alias ExIntegrate.Core.Run

  @spec run_pipelines_from_file(filename :: binary) :: {:ok, Run.t()}
  def run_pipelines_from_file(filename) do
    params = import_json(filename)
    run_pipelines(params)
  end

  @spec run_pipelines(map) :: {:ok, Run.t()}
  def run_pipelines(params) when is_map(params) do
    config = Run.new(params)

    results = Enum.map(config.pipelines, &Runner.run_pipeline/1)

    if Enum.any?(results, fn pipeline -> pipeline.failed? end) do
      {:error, %{config | pipelines: results}}
    else
      {:ok, %{config | pipelines: results}}
    end
  end

  defp import_json(filename) do
    filename
    |> File.read!()
    |> Jason.decode!()
  end
end
