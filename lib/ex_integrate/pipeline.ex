defmodule ExIntegrate.Core.Pipeline do
  @moduledoc """
  A collection of Steps to be run sequentially.
  """

  alias ExIntegrate.Core.Step
  alias ExIntegrate.Core.Zipper

  @behaviour Access

  @enforce_keys [:name, :steps]
  defstruct @enforce_keys ++ [failed?: false]

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

  @spec fail(t) :: t
  def fail(%__MODULE__{} = pipeline),
    do: %{pipeline | failed?: true}

  @spec failed?(t) :: boolean
  def failed?(%__MODULE__{} = pipeline),
    do: pipeline.failed?

  @spec complete?(t) :: boolean
  def complete?(%__MODULE__{} = pipeline),
    do: failed?(pipeline) or Zipper.end?(pipeline.steps)

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

  @spec get_step_by_name(t, String.t()) :: Step.t()
  def get_step_by_name(%__MODULE__{} = pipeline, step_name) do
    pipeline
    |> steps()
    |> Enum.find(&(&1.name == step_name))
  end

  @spec replace_current_step(t, Step.t()) :: t
  def replace_current_step(%__MODULE__{} = pipeline, %Step{} = step) do
    put_step(pipeline, current_step(pipeline), step)
  end

  def replace_step_and_advance(%__MODULE__{} = pipeline, %Step{} = step) do
    pipeline
    |> replace_current_step(step)
    |> advance()
  end

  @spec put_step(t, Step.t(), Step.t()) :: t
  def put_step(
        %__MODULE__{} = pipeline,
        %Step{name: name} = _old_step,
        %Step{name: name} = new_step
      ) do
    pipeline
    |> Map.update(:steps, pipeline.steps, fn steps ->
      index = pipeline |> steps() |> Enum.find_index(&(&1.name == name))
      Zipper.replace_at(steps, index, new_step)
    end)
    |> Map.put(:failed?, pipeline.failed? || Step.failed?(new_step))
  end

  def put_step(%__MODULE__{}, %Step{} = old_step, %Step{} = new_step) do
    raise ArgumentError,
          """
          cannot alter step names after creation!

          Old step: #{inspect(old_step)},

          Attempted new step: #{inspect(new_step)}
          """
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
