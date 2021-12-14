defmodule ExIntegrate.Boundary.PipelineRunnerTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias ExIntegrate.Boundary.PipelineRunner
  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Step

  test "runs a pipeline" do
    step = Step.new(name: "echo", command: "echo", args: ["pass me"])
    pipeline = Pipeline.new(name: "a pipeline", steps: [step])
    test_process = self()

    log_func = fn result ->
      send(test_process, result)
    end

    server = start_supervised!({PipelineRunner, {pipeline, %{log: log_func}}})
    assert_receive {:stdout, "pass me\n"}
  end
end
