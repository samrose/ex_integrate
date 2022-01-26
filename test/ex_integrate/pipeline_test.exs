defmodule ExIntegrate.PipelineTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Step

  test "get a pipeline's step by name" do
    step = Step.new(name: "my step", command: "foo", args: [])
    pipeline = Pipeline.new(name: "my pipeline", steps: [step])

    assert pipeline[step.name] == step
  end

  test "update a pipeline's step" do
    step = Step.new(name: "my step", command: "foo", args: [])
    pipeline = Pipeline.new(name: "my pipeline", steps: [step])
    updated_step = %{step | status_code: 0}

    assert Pipeline.put_step(pipeline, step, updated_step)
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
    step1 = Step.new(name: "a step #{System.unique_integer()}", command: "foo", args: [])
    step2 = Step.new(name: "a step #{System.unique_integer()}", command: "foo", args: [])
    pipeline = Pipeline.new(%{name: "my pipeline", steps: [step1, step2]})
    updated_step = %{step2 | status_code: Enum.random([0, 1, 2, 3])}

    updated_pipeline =
      pipeline
      |> Pipeline.advance()
      |> Pipeline.replace_current_step(updated_step)

    assert Pipeline.current_step(updated_pipeline) == updated_step
  end
end
