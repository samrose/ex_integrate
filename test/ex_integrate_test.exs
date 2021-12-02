defmodule ExIntegrateTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Run
  alias ExIntegrate.Core.Step

  @config_fixture_path "test/fixtures/ei.test.json"

  describe "running the steps from a config file" do
    test "success: runs pipeline steps in order and returns success tuple" do
      run_pipelines_from_file = fn ->
        assert {:ok, %Run{}} = ExIntegrate.run_pipelines_from_file(@config_fixture_path)
      end

      assert capture_io(run_pipelines_from_file) == "step 1\nstep 2\nstep 3\n"
    end

    test "when file doesn't exist, raises error" do
      assert_raise File.Error,
                   fn -> ExIntegrate.run_pipelines_from_file("nonexistant_file") end
    end
  end

  describe "run" do
    @failing_script "test/fixtures/error_1.sh"

    test "when all steps pass, returns :ok tuple with run data" do
      config_params = %{
        "pipelines" => [
          %{
            "steps" => [
              %{
                "name" => "passing step",
                "command" => "echo",
                "args" => ["I will pass"]
              }
            ]
          }
        ]
      }

      run_fn = fn ->
        assert {:ok, %Run{}} = ExIntegrate.run_pipelines(config_params)
      end

      assert capture_io(run_fn) == "I will pass\n"
    end

    test "when a step fails, returns error tuple" do
      config_params = %{
        "pipelines" => [
          %{
            "steps" => [
              %{
                "name" => "failing step",
                "command" => "bash",
                "args" => [@failing_script]
              }
            ]
          }
        ]
      }

      assert {:error, _} = ExIntegrate.run_pipelines(config_params)
    end
  end
end
