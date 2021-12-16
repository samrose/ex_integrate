defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  alias ExIntegrate.Boundary.PipelineRunner
  alias ExIntegrate.Boundary.ConfigParser
  alias ExIntegrate.Core.Run

  @spec run_pipelines_from_file(filename :: binary) :: {:ok, Run.t()} | {:error, Run.t()}
  def run_pipelines_from_file(filename) do
    params = ConfigParser.import_json(filename)
    run_pipelines(params)
  end

  @spec run_pipelines(map) :: {:ok, Run.t()} | {:error, Run.t()}
  def run_pipelines(params) when is_map(params) do
    run = Run.new(params)

    completed_pipelines =
      run
      |> Run.pipelines()
      |> Enum.map(&PipelineRunner.run_pipeline/1)

    if Enum.any?(completed_pipelines, fn pipeline -> pipeline.failed? end) do
      {:error, %{run | pipelines: completed_pipelines}}
    else
      {:ok, %{run | pipelines: completed_pipelines}}
    end
  end
end
