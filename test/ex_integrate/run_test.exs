defmodule ExIntegrate.RunTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Core.Run
  alias ExIntegrate.Core.Pipeline

  @pipeline_params %{
    "name" => "say hello",
    "steps" => [
      %{
        "name" => "say hello",
        "command" => "echo",
        "args" => ["hello"]
      }
    ]
  }

  @dependent_pipeline_params %{
    "depends_on" => "say hello",
    "name" => "say world",
    "steps" => [
      %{
        "name" => "say world",
        "command" => "echo",
        "args" => ["world!"]
      }
    ]
  }

  @run_params %{
    "pipelines" => [@pipeline_params]
  }

  @dependent_run_params %{
    "pipelines" => [@pipeline_params, @dependent_pipeline_params]
  }

  test "create a run with a dependent pipeline" do
    run = Run.new(@dependent_run_params)
    [pipeline1 | [pipeline2 | []]] = Run.pipelines(run)
    assert [^pipeline1] = Graph.neighbors(run.pipelines, pipeline2)
  end

  describe "updating a pipeline" do
    test "on pipeline success, updates the pipelines" do
      run = Run.new(@run_params)
      assert pipeline = run |> Run.pipelines() |> hd()
      updated_pipeline = pipeline |> Pipeline.advance()

      run = Run.put_pipeline(run, pipeline, updated_pipeline)
      refute Run.failed?(run), "Expected run not to have failed. #{inspect(run)}"

      assert Run.has_pipeline?(run, updated_pipeline),
             """
             Expected pipelines:

             #{inspect(run.pipelines)}

             to include pipeline:

             #{inspect(pipeline)}.
             """
    end

    test "if updated pipeline failed, then the run has failed" do
      run = Run.new(@run_params)
      refute Run.failed?(run)

      pipeline = run |> Run.pipelines() |> hd()
      step = pipeline |> Pipeline.steps() |> hd
      failed_pipeline = Pipeline.put_step(pipeline, step, %{step | status_code: 1})
      failed_run = Run.put_pipeline(run, pipeline, failed_pipeline)

      assert Run.failed?(failed_run),
             "Expected run to have failed.\n\n#{inspect(failed_run)}"
    end
  end

  test "look up a pipeline by name" do
    run = Run.new(%{"pipelines" => [@pipeline_params]})
    pipeline_name = @pipeline_params["name"]
    assert %Pipeline{} = run[pipeline_name]
  end

  test "get and update a run's pipeline" do
    run = Run.new(%{"pipelines" => [@pipeline_params]})
    %{name: pipeline_name} = pipeline = run |> Run.pipelines() |> hd
    updated_pipeline = pipeline |> Pipeline.advance()

    assert {%{name: ^pipeline_name}, updated_run} =
             Run.get_and_update(run, pipeline_name, fn pipeline ->
               {pipeline, updated_pipeline}
             end)

    assert ^updated_pipeline = updated_run[updated_pipeline.name]
  end

  test "return the next pipelines to launch" do
    run = Run.new(%{"pipelines" => [@pipeline_params, @dependent_pipeline_params]})
    first_pipeline = run[@pipeline_params["name"]]
    second_pipeline = run[@dependent_pipeline_params["name"]]

    assert [^second_pipeline] = Run.next_pipelines(run, first_pipeline)
  end

  @tag :skip
  test "updates whether pipelines have been run or SHOULD be run" do
    flunk("""
    Consider decorating the pipeline graph with Libgraph's labels for Edges or
    Vertices to designate whether a pipeline/edge has been traversed, or
    SHOULD be traversed. Ideally move all logic for detecting whether to
    proceed to the next pipeline to the core Run module, and depend on it from
    RunManager.

    It would be good to replace the simple counter with a better, more flexible,
    pure functional, and better-tested implementation.
    """)
  end
end
