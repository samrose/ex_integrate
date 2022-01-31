defmodule ExIntegrateTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.Run

  @config_fixture_path "test/fixtures/ei.test.json"
  @moduletag timeout: 10_000

  describe "running the steps from a config file" do
    test "success: runs pipeline steps in order and returns success tuple" do
      assert {:ok, %Run{}} = ExIntegrate.run_from_file(@config_fixture_path)
    end

    test "when file doesn't exist, raises error" do
      assert_raise File.Error, fn ->
        ExIntegrate.run_from_file("nonexistant_file")
      end
    end
  end

  describe "run" do
    @run_params %{
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

    test "when all steps pass, returns :ok tuple with run data" do
      assert {:ok, %Run{}} = ExIntegrate.run(@run_params)
    end

    @failing_run_params %{
      "pipelines" => [
        %{
          "steps" => [
            %{
              "name" => "failing step",
              "command" => "cat",
              "args" => ["nonexistant"]
            }
          ]
        }
      ]
    }

    test "when a step fails, returns error tuple with run data" do
      assert {:error, %Run{}} = ExIntegrate.run(@failing_run_params)
    end
  end
end
