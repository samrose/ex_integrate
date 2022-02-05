defmodule ExIntegrate do
  @moduledoc File.read!("README.md")

  alias ExIntegrate.Boundary.Server
  alias ExIntegrate.Boundary.ConfigParser
  alias ExIntegrate.Core.Run

  @spec run_from_file(filename :: binary) :: {:ok, Run.t()} | {:error, Run.t()}
  def run_from_file(filename) do
    params = ConfigParser.import_json(filename)
    run(params)
  end

  @spec run(map) :: {:ok, Run.t()} | {:error, Run.t()}
  def run(params) when is_map(params) do
    run = Run.new(params)
    Server.run(run)
  end
end
