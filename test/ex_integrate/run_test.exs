defmodule ExIntegrate.RunTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.Run
  alias ExIntegrate.Core.Pipeline

  @valid_params %{
    "pipelines" => [
      %{
        "steps" => [
          %{
            "name" => "say hello",
            "command" => "echo",
            "args" => ["hello world!"]
          }
        ]
      }
    ]
  }

  test "update pipeline" do
    assert %Run{} = run = Run.new(@valid_params)
    assert pipeline = hd(run.pipelines)
    updated_pipeline = %Pipeline{name: "updated pipeline", steps: []}

    assert run = Run.put_pipeline(run, pipeline, updated_pipeline)

    assert Run.has_pipeline?(run, updated_pipeline),
           """
           Expected pipeline graph:

           #{inspect(run.pipeline_graph)}

           to have pipeline:

           #{inspect(pipeline)}.
           """
  end

  test "checks if a pipeline has failed" do
    run = Run.new(@valid_params)
    refute Run.failed?(run)
  end
end
