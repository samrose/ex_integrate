defmodule ExIntegrate.Boundary.PipelineRunnerTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExIntegrate.Boundary.PipelineRunner
  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Step

  @timeout 1_000

  setup :create_steps

  test "runs a pipeline", %{steps: steps} do
    pipeline_name = "a pipeline"
    pipeline = Pipeline.new(name: pipeline_name, steps: steps)

    {test_process, ref} = {self(), make_ref()}

    on_completion = fn pipeline, _msg ->
      success_or_failure = result(pipeline, &Pipeline.failed?/1)
      send(test_process, {success_or_failure, ref, pipeline.name})
    end

    start_supervised!({PipelineRunner, {pipeline, [on_completion: on_completion]}})
    assert_receive {:success, ^ref, ^pipeline_name}, @timeout
  end

  defp create_steps(_) do
    int = Enum.random(1..10)
    steps = Stream.repeatedly(&create_step/0) |> Enum.take(int)

    [steps: steps]
  end

  defp create_step(),
    do: Step.new(name: "echo", command: "exit", args: ["0"])

  defp result(val, fun) do
    if fun.(val),
      do: :failure,
      else: :success
  end
end
