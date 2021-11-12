defmodule Mix.Tasks.EiTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Ei, as: EiTask

  @ei_config_path "test/fixtures/ei.test.json"

  test "runs an ExIntegrate build using the config file" do
    assert EiTask.run(["--config", @ei_config_path]) ==
             ExIntegrate.run_pipelines_from_file(@ei_config_path)
  end
end
