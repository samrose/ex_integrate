defmodule ExIntegrate.Core.Run do
  alias ExIntegrate.Core.Pipeline

  @behaviour Access

  @enforce_keys [:pipelines]
  defstruct @enforce_keys ++ [active_pipelines: []]

  @type t :: %__MODULE__{
          active_pipelines: [Pipeline.t()],
          pipelines: Graph.t()
        }

  @type pipeline_root :: :root
  @root_vertex :root

  @spec new(params :: map) :: t()
  def new(params) do
    pipelines = set_up_pipeline_graph(params)

    struct!(__MODULE__, pipelines: pipelines)
  end

  defp set_up_pipeline_graph(params) do
    pipelines = params["pipelines"] || []
    initial_graph = Graph.new(type: :directed) |> Graph.add_vertex(@root_vertex)
    Enum.reduce(pipelines, initial_graph, &add_pipeline_to_graph/2)
  end

  defp add_pipeline_to_graph(pipeline_attrs, graph) do
    pipeline = Pipeline.new(pipeline_attrs)

    case pipeline_attrs["depends_on"] do
      nil ->
        Graph.add_edge(graph, @root_vertex, pipeline, [pipeline_attrs["name"]])

      dependent_pipeline_name ->
        dependent_pipeline = look_up_pipeline(graph, dependent_pipeline_name)
        Graph.add_edge(graph, dependent_pipeline, pipeline)
    end
  end

  defp look_up_pipeline(pipeline_graph, pipeline_name) do
    pipeline_graph
    |> Graph.vertices()
    |> Enum.find(fn
      %{name: name} when name == pipeline_name -> true
      _ -> false
    end)
  end

  @doc """
  Updates the given pipeline in the run's collection.

  Returns the run with updated pipeline.
  """
  @spec put_pipeline(t(), Pipeline.t(), Pipeline.t()) :: t()
  def put_pipeline(%__MODULE__{} = run, %Pipeline{} = old_pipeline, %Pipeline{} = new_pipeline) do
    do_put_pipeline(run, old_pipeline, new_pipeline)
  end

  def put_pipeline(%__MODULE__{} = run, old_pipeline_name, %Pipeline{} = new_pipeline) do
    old_pipeline = run[old_pipeline_name]
    do_put_pipeline(run, old_pipeline, new_pipeline)
  end

  defp do_put_pipeline(run, old_pipeline, new_pipeline) do
    Map.put(
      run,
      :pipelines,
      Graph.replace_vertex(run.pipelines, old_pipeline, new_pipeline)
    )
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
    Graph.has_vertex?(run.pipelines, pipeline)
  end

  @spec failed?(t()) :: boolean
  def failed?(%__MODULE__{} = run) do
    run
    |> pipelines()
    |> Enum.any?(&Pipeline.failed?/1)
  end

  def root_vertex(%__MODULE__{} = run) do
    if Graph.has_vertex?(run.pipelines, @root_vertex) do
      @root_vertex
    else
      raise "graph is missing root node #{inspect(run)}"
    end
  end

  @spec pipelines(t()) :: [Pipeline.t()]
  def pipelines(%__MODULE__{} = run),
    do: Graph.vertices(run.pipelines) |> Enum.filter(&match?(%Pipeline{}, &1))

  @spec next_pipelines(t(), Pipeline.t() | pipeline_root) :: [Pipeline.t()]
  def next_pipelines(%__MODULE__{} = run, pipeline) do
    Graph.out_neighbors(run.pipelines, pipeline)
  end

  @impl Access
  def fetch(%__MODULE__{} = run, pipeline_name) do
    {:ok, look_up_pipeline(run.pipelines, pipeline_name)}
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
