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
end
