defmodule ExIntegrate.Core.Run do
  alias ExIntegrate.Core.Pipeline

  @behaviour Access

  @enforce_keys [:pipelines]
  defstruct @enforce_keys ++ [active_pipelines: [], pipeline_graph: nil]

  @type t :: %__MODULE__{
          active_pipelines: [Pipeline.t()],
          pipelines: [Pipeline.t()],
          pipeline_graph: Graph.t()
        }

  @spec new(params :: map) :: t()
  def new(params) do
    pipelines = set_up_pipeline_legacy(params)
    pipeline_graph = set_up_pipeline_graph(params)

    struct!(__MODULE__, pipelines: pipelines, pipeline_graph: pipeline_graph)
  end

  defp set_up_pipeline_legacy(params) do
    Enum.map(params["pipelines"], &Pipeline.new/1)
  end

  defp set_up_pipeline_graph(params) do
    Enum.reduce(params["pipelines"], Graph.new(type: :directed), fn pipeline_attrs, graph ->
      pipeline = Pipeline.new(pipeline_attrs)

      case pipeline_attrs["depends_on"] do
        nil ->
          Graph.add_vertex(graph, pipeline, [pipeline_attrs["name"]])

        dependent_pipeline_name ->
          dependent_pipeline = look_up_pipeline(graph, dependent_pipeline_name)
          edge = Graph.Edge.new(dependent_pipeline, pipeline)
          Graph.add_edge(graph, edge)
      end
    end)
  end

  defp look_up_pipeline(pipeline_graph, pipeline_name) do
    pipeline_graph
    |> Graph.vertices()
    |> Enum.find(fn pipeline -> pipeline.name == pipeline_name end)
  end

  @doc """
  Updates the given pipeline in the run's collection.

  Returns the run with updated pipeline.
  """
  @spec put_pipeline(t(), Pipeline.t(), Pipeline.t()) :: t()
  def put_pipeline(%__MODULE__{} = run, %Pipeline{} = old_pipeline, %Pipeline{} = new_pipeline) do
    do_put_pipeline(run, old_pipeline, new_pipeline)
  end

  def put_pipeline(%__MODULE__{} = run, old_pipeline_name, %Pipeline{} = new_pipeline)
      when is_binary(old_pipeline_name) or is_atom(old_pipeline_name) do
    old_pipeline = run[old_pipeline_name]
    do_put_pipeline(run, old_pipeline, new_pipeline)
  end

  defp do_put_pipeline(run, old_pipeline, new_pipeline) do
    updated_pipeline_graph = Graph.replace_vertex(run.pipeline_graph, old_pipeline, new_pipeline)
    Map.put(run, :pipeline_graph, updated_pipeline_graph)
  end

  def activate_pipelines(%__MODULE__{} = run, pipelines) when is_list(pipelines) do
    %{run | active_pipelines: pipelines}
  end

  def active_pipelines(%__MODULE__{} = run), do: run.active_pipelines

  @doc """
  Returns true if the pipeline is included in the run; otherwise, returns false.
  """
  @spec has_pipeline?(t(), Pipeline.t()) :: boolean
  def has_pipeline?(%__MODULE__{} = run, %Pipeline{} = pipeline) do
    Graph.has_vertex?(run.pipeline_graph, pipeline)
  end

  @spec failed?(t()) :: boolean
  def failed?(%__MODULE__{} = run) do
    run
    |> pipelines()
    |> Enum.any?(&Pipeline.failed?/1)
  end

  @spec pipelines(t()) :: [Pipeline.t()]
  def pipelines(%__MODULE__{} = run),
    do: Graph.vertices(run.pipeline_graph)

  @impl Access
  def fetch(%__MODULE__{} = run, pipeline_name) do
    {:ok, look_up_pipeline(run.pipeline_graph, pipeline_name)}
  end

  @impl Access
  def pop(%__MODULE__{} = _run, _pipeline_name) do
    raise "do not pop a run's pipelines"
  end

  @impl Access
  def get_and_update(%__MODULE__{} = run, pipeline_name, fun) when is_function(fun) do
    current = run[pipeline_name]

    case fun.(current) do
      {get, update} ->
        {get, put_pipeline(run, pipeline_name, update)}

      :pop ->
        raise "popping a pipeline is not allowed"

      other ->
        raise "the given function must return a two-element tuple; got #{inspect(other)}"
    end
  end
end
