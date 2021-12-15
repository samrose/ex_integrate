defmodule ExIntegrate.Boundary.PipelineRunnerTest do
  use ExUnit.Case

  alias ExIntegrate.Boundary.PipelineRunner
  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Step

  @moduletag capture_log: false
  test "runs a pipeline with two steps" do
    step1 = Step.new(name: "echo", command: "echo", args: ["pass me"])
    step2 = Step.new(name: "echo", command: "echo", args: ["pass me again"])
    pipeline = Pipeline.new(name: "a pipeline", steps: [step1, step2])
    test_process = self()

    log_func = fn result ->
      send(test_process, result)
    end

    start_supervised!({PipelineRunner, {pipeline, %{log: log_func}}})

    assert_receive {_io_type, "pass me\n"}
    assert_receive {_io_type, "pass me again\n"}
  end
end
