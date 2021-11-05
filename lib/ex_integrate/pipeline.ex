defmodule ExIntegrate.Pipeline do
  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner

  @type t :: %__MODULE__{
          failed?: binary,
          steps: [Step.t()],
          completed_steps: [Step.t()],
          remaining_steps: [Step.t()]
        }

  defstruct [:steps, :failed?, :completed_steps, :remaining_steps]

  @spec run(t()) :: t()
  def run(%__MODULE__{} = pipeline) do
    Enum.reduce(pipeline.steps, pipeline, fn step, acc ->
      case StepRunner.run_step(step) do
        {:ok, step} ->
          complete_step(acc, step)

        {:error, _error} ->
          acc
          |> complete_step(step)
          |> fail()
      end
    end)
  end

  def complete_step(%__MODULE__{} = pipeline, %Step{} = step),
    do: %{pipeline | completed_steps: [step] ++ pipeline.completed_steps}

  def fail(%__MODULE__{} = pipeline),
    do: %{pipeline | failed?: true}
end
