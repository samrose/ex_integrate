defmodule ExIntegrate.Core.Run do
  alias ExIntegrate.Core.Pipeline
  alias ExIntegrate.Core.Step

  @enforce_keys [:pipelines]
  defstruct @enforce_keys ++ [:pipeline_graph]

  @type t :: %__MODULE__{
          pipelines: [Pipeline.t()],
          pipeline_graph: Graph.t()
        }

  @spec new(params :: map) :: t()
  def new(params) do
    pipelines =
      params
      |> Access.fetch!("pipelines")
      |> Enum.map(fn pipeline_attrs ->
        steps = Enum.map(pipeline_attrs["steps"], &Step.new/1)
        %Pipeline{name: pipeline_attrs["name"], steps: steps}
      end)

    pipeline_graph = set_up_pipeline_graph(pipelines)
    struct!(__MODULE__, pipelines: pipelines, pipeline_graph: pipeline_graph)
  end

  # TODO: set up edges
  defp set_up_pipeline_graph(pipelines) do
    Graph.new(type: :directed)
    |> Graph.add_vertices(pipelines)
  end

  @doc """
  Updates the given pipeline in the run's collection.

  Returns the run with updated pipeline.
  """
  @spec put_pipeline(t(), Pipeline.t(), Pipeline.t()) :: t()
  def put_pipeline(%__MODULE__{} = run, %Pipeline{} = old_pipeline, %Pipeline{} = new_pipeline) do
    updated_pipeline_graph = Graph.replace_vertex(run.pipeline_graph, old_pipeline, new_pipeline)
    Map.put(run, :pipeline_graph, updated_pipeline_graph)
  end

  @doc """
  Returns true if the pipeline is included in the run; otherwise, returns false.
  """
  @spec has_pipeline?(t(), Pipeline.t()) :: boolean
  def has_pipeline?(%__MODULE__{} = run, %Pipeline{} = pipeline) do
    Graph.has_vertex?(run.pipeline_graph, pipeline)
  end

  def failed?(%__MODULE__{} = run) do
    run
    |> pipelines()
    |> Enum.any?(& &1.failed?)
  end

  defp pipelines(run), do: Graph.vertices(run.pipeline_graph)
end
