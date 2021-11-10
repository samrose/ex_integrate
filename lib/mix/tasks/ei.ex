defmodule Mix.Tasks.Ei do
  @moduledoc """
  Runs an ExIntegrate build using the provided config file, or `ei.json` by default.
  """

  use Mix.Task

  @default_config_path "ei.json"

  @impl Mix.Task
  def run(args) do
    {parsed, _args, _opts} = parse_opts(args)
    ei_config_file = Keyword.get(parsed, :config, @default_config_path)

    ExIntegrate.run_pipelines_from_file(ei_config_file)
  end

  defp parse_opts(opts) do
    OptionParser.parse(opts, switches: [config: :string])
  end
end
