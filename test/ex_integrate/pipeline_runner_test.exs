defmodule ExIntegrate.Boundary.PipelineRunnerTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Boundary.PipelineRunner
  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Step

  test "runs a pipeline with two steps" do
    step1 = Step.new(name: "echo", command: "echo", args: ["pass me"])
    step2 = Step.new(name: "echo", command: "echo", args: ["pass me again"])
    pipeline = Pipeline.new(name: "a pipeline", steps: [step1, step2])
    test_process = self()
    ref = make_ref()

    log_func = fn result ->
      send(test_process, {:log, ref, result})
    end

    start_supervised!({PipelineRunner, [pipeline: pipeline, log: log_func]})

    assert_receive {:log, ^ref, {_io_type, "pass me\n"}}
    assert_receive {:log, ^ref, {_io_type, "pass me again\n"}}
  end
end
