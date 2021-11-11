defmodule ExIntegrate.PipelineTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.{Pipeline, Step}

  test "get a pipeline's step by name" do
    step = %Step{name: "my step", command: "foo", args: []}

    pipeline = %Pipeline{
      name: "my pipeline",
      steps: [step]
    }

    assert pipeline[step.name] == step
  end
end
