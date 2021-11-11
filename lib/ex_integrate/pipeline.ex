defmodule ExIntegrate.Core.Pipeline do
  alias ExIntegrate.Core.Step

  @enforce_keys [:name, :steps]
  defstruct @enforce_keys ++ [failed?: false, completed_steps: []]

  @type t :: %__MODULE__{
          failed?: binary,
          name: String.t(),
          steps: [Step.t()],
          completed_steps: [Step.t()]
        }

  def complete_step(%__MODULE__{} = pipeline, %Step{} = step),
    do: %{pipeline | completed_steps: [step] ++ pipeline.completed_steps}

  def fail(%__MODULE__{} = pipeline),
    do: %{pipeline | failed?: true}

  def failed?(%__MODULE__{} = pipeline),
    do: Enum.any?(pipeline.steps, &Step.failed?/1)
end
