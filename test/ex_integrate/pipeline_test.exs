defmodule ExIntegrate.PipelineTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.{Pipeline, Step}

  test "get a pipeline's step by name" do
    step = %Step{name: "my step", command: "foo", args: []}
    pipeline = %Pipeline{name: "my pipeline", steps: [step]}

    assert pipeline[step.name] == step
  end

  test "update a pipeline's step" do
    step = %Step{name: "my step", command: "foo", args: []}
    pipeline = %Pipeline{name: "my pipeline", steps: [step]}
    updated_step = %{step | status_code: 0}

    assert Pipeline.put_step(pipeline, step, updated_step)
  end

  test "get and update a pipeline's step" do
    step = %Step{name: "my step", command: "foo", args: []}
    pipeline = %Pipeline{name: "my pipeline", steps: [step]}
    updated_step = %{step | status_code: 0}

    assert Pipeline.get_and_update(pipeline, step.name, fn current_step ->
             {current_step, updated_step}
           end)
  end

  test "get the next step in the queue" do
    step1 = %Step{name: "my step 1", command: "foo", args: []}
    step2 = %Step{name: "my step 2", command: "foo", args: []}
    pipeline = Pipeline.new(%{name: "my pipeline", steps: [step1, step2]})

    assert {%Step{}, %Pipeline{}} = Pipeline.pop_step(pipeline)
  end
end
