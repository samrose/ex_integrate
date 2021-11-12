defmodule ExIntegrate.Core.Pipeline do
  alias ExIntegrate.Core.Step

  @behaviour Access

  @enforce_keys [:name, :steps]
  defstruct @enforce_keys ++ [failed?: false, completed_steps: []]

  @type t :: %__MODULE__{
          failed?: binary,
          name: String.t(),
          steps: %{optional(non_neg_integer) => Step.t()},
          completed_steps: [Step.t()]
        }

  def new(attrs) do
    steps = Enum.map(attrs["steps"], &Step.new/1)
    struct!(__MODULE__, name: attrs["name"], steps: steps)
  end

  def complete_step(%__MODULE__{} = pipeline, %Step{} = step),
    do: %{pipeline | completed_steps: [step] ++ pipeline.completed_steps}

  def fail(%__MODULE__{} = pipeline),
    do: %{pipeline | failed?: true}

  def failed?(%__MODULE__{} = pipeline),
    do: Enum.any?(pipeline.steps, &Step.failed?/1)

  def steps(%__MODULE__{} = pipeline), do: pipeline.steps

  def put_step(%__MODULE__{} = pipeline, %Step{} = old_step, %Step{} = new_step) do
    i = pipeline |> steps |> Enum.find_index(fn step -> step.name == old_step.name end)

    pipeline
    |> steps()
    |> List.replace_at(i, new_step)
  end

  @impl Access
  def fetch(%__MODULE__{} = pipeline, step_name) when is_binary(step_name) do
    {:ok, get_step_by_name(pipeline, step_name)}
  end

  @impl Access
  def get_and_update(%__MODULE__{} = pipeline, step_name, fun) when is_function(fun, 1) do
    current = get_step_by_name(pipeline, step_name)

    case fun.(current) do
      {get, update} ->
        {get, put_step(pipeline, current, update)}

      :pop ->
        raise "cannot pop steps!"

      other ->
        raise "the given function must return a two-element tuple or :pop; got: #{inspect(other)}"
    end
  end

  def get_step_by_name(%__MODULE__{} = pipeline, step_name) do
    pipeline
    |> steps()
    |> Enum.find(fn step -> step.name == step_name end)
  end

  @impl Access
  def pop(_pipeline, _step), do: raise("cannot pop steps!")
end
