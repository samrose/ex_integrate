defmodule ExIntegrate.PipelineTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Step

  test "get a pipeline's step by name" do
    step = Step.new(name: "my step", command: "foo", args: [])
    pipeline = Pipeline.new(name: "my pipeline", steps: [step])

    assert pipeline[step.name] == step
  end

  describe "updating a pipeline's step" do
    test "updates the step" do
      step = Step.new(name: "my step", command: "foo", args: [])
      pipeline = Pipeline.new(name: "my pipeline", steps: [step])
      updated_step = %{step | status_code: 0}

      updated_pipeline = Pipeline.put_step(pipeline, step, updated_step)
      assert updated_step in Pipeline.steps(updated_pipeline)
    end

    test "flags step failure" do
      step = Step.new(name: "my step", command: "foo", args: [])
      pipeline = Pipeline.new(name: "my pipeline", steps: [step])
      updated_step = %{step | status_code: 1}

      updated_pipeline = Pipeline.put_step(pipeline, step, updated_step)
      assert Pipeline.failed?(updated_pipeline)
    end
  end

  test "get and update a pipeline's step" do
    step = Step.new(name: "my step", command: "foo", args: [])
    pipeline = Pipeline.new(name: "my pipeline", steps: [step])
    updated_step = %{step | status_code: 0}

    assert Pipeline.get_and_update(pipeline, step.name, fn current_step ->
             {current_step, updated_step}
           end)
  end

  test "advance to the next step" do
    step1 = Step.new(name: "a step #{System.unique_integer()}", command: "foo", args: [])
    step2 = Step.new(name: "a step #{System.unique_integer()}", command: "foo", args: [])
    pipeline = Pipeline.new(%{name: "my pipeline", steps: [step1, step2]})

    pipeline = pipeline |> Pipeline.advance() |> Pipeline.advance()
    assert Pipeline.current_step(pipeline) == step2
  end

  test "replace the current step" do
    step1 = Step.new(name: "#{System.unique_integer()}", command: "foo", args: [])
    step2 = Step.new(name: "#{System.unique_integer()}", command: "foo", args: [])
    pipeline = Pipeline.new(%{name: "my pipeline", steps: [step1, step2]})

    updated_step2 = %{step2 | status_code: Enum.random([0, 1, 2, 3])}

    updated_pipeline =
      pipeline
      |> Pipeline.advance()
      |> Pipeline.advance()
      |> Pipeline.replace_current_step(updated_step2)

    assert Pipeline.current_step(updated_pipeline) == updated_step2
  end

  describe "check if pipeline is complete" do
    setup do
      step1 = Step.new(name: "#{System.unique_integer()}", command: "foo", args: [])
      step2 = Step.new(name: "#{System.unique_integer()}", command: "foo", args: [])
      [step1: step1, step2: step2]
    end

    test "when all steps are complete: true", %{step1: step1, step2: step2} do
      completed_pipeline =
        %{name: "my pipeline", steps: [step1, step2]}
        |> Pipeline.new()
        |> Pipeline.advance()
        |> Pipeline.advance()
        |> Pipeline.advance()

      assert Pipeline.complete?(completed_pipeline),
             "Expected pipeline to be completed, but it was not\n\n#{inspect(completed_pipeline)}"
    end

    test "when pipeline has failed: true", %{step1: step1, step2: step2} do
      failed_step2 = %{step2 | status_code: 1}

      failed_pipeline =
        %{name: "my pipeline", steps: [step1, step2]}
        |> Pipeline.new()
        |> Pipeline.advance()
        |> Pipeline.advance()
        |> Pipeline.replace_current_step(failed_step2)

      assert Pipeline.complete?(failed_pipeline),
             "Expected pipeline to be completed, but it was not\n\n#{inspect(failed_pipeline)}"
    end
  end
end
