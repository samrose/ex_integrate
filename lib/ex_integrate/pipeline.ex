defmodule ExIntegrate.Core.Pipeline do
  @moduledoc """
  A collection of Steps to be run sequentially.
  """

  alias ExIntegrate.Core.Step
  alias ExIntegrate.Core.Zipper

  @behaviour Access

  @enforce_keys [:name, :steps]
  defstruct @enforce_keys ++ [failed?: false, completed_steps: []]

  @type key :: String.t()

  @type t :: %__MODULE__{
          failed?: boolean,
          name: key,
          steps: Zipper.t(Step.t())
        }

  @spec new(Enum.t()) :: t
  def new(fields) do
    fields = update_in(fields[:steps], &Zipper.zip/1)
    struct!(__MODULE__, fields)
  end

  @spec complete_step(t, Step.t()) :: t
  def complete_step(%__MODULE__{} = pipeline, %Step{} = step),
    do: %{pipeline | completed_steps: [step] ++ pipeline.completed_steps}

  @spec fail(t) :: t
  def fail(%__MODULE__{} = pipeline),
    do: %{pipeline | failed?: true}

  @spec failed?(t) :: boolean
  def failed?(%__MODULE__{} = pipeline),
    do: pipeline.failed?

  @spec complete?(t) :: boolean
  def complete?(%__MODULE__{} = pipeline),
    do: Zipper.end?(pipeline.steps)

  @spec steps(t) :: [Step.t()]
  def steps(%__MODULE__{} = pipeline),
    do: Zipper.to_list(pipeline.steps)

  @spec pop_step(t()) :: {Step.t(), t()}
  def pop_step(%__MODULE__{} = pipeline) do
    Map.get_and_update(pipeline, :steps, fn steps ->
      {{:value, value}, _} = :queue.out(steps)
      {value, steps}
    end)
  end

  @spec advance(t) :: t
  def advance(%__MODULE__{} = pipeline),
    do: %{pipeline | steps: Zipper.right(pipeline.steps)}

  @spec current_step(t) :: Step.t() | nil
  def current_step(%__MODULE__{} = pipeline),
    do: Zipper.node(pipeline.steps)

  @spec replace_current_step(t, Step.t()) :: t
  def replace_current_step(%__MODULE__{} = pipeline, %Step{} = step) do
    updated_steps = Zipper.put_current(pipeline.steps, step)
    %{pipeline | steps: updated_steps}
  end

  @spec get_step_by_name(t, String.t()) :: Step.t()
  def get_step_by_name(%__MODULE__{} = pipeline, step_name) do
    pipeline
    |> steps()
    |> Enum.find(fn step -> step.name == step_name end)
  end

  @spec put_step(t, Step.t(), Step.t()) :: t
  def put_step(%__MODULE__{} = pipeline, %Step{} = old_step, %Step{} = new_step) do
    i = pipeline |> steps |> Enum.find_index(fn step -> step.name == old_step.name end)

    pipeline
    |> steps()
    |> List.replace_at(i, new_step)
  end

  @impl Access
  @spec fetch(t, String.t()) :: {:ok, Step.t()}
  def fetch(%__MODULE__{} = pipeline, step_name) do
    {:ok, get_step_by_name(pipeline, step_name)}
  end

  @impl Access
  @spec get_and_update(t, String.t(), function) :: {Step.t(), t} | no_return
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

  @impl Access
  @spec pop(term, term) :: no_return
  def pop(_pipeline, _step), do: raise("cannot pop steps!")
end
