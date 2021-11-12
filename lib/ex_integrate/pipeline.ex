defmodule ExIntegrate.Core.Pipeline do
  alias ExIntegrate.Core.Step

  @type t :: %__MODULE__{
          failed?: binary,
          steps: [Step.t()],
          completed_steps: [Step.t()]
        }

  defstruct [:steps, :failed?, :completed_steps]

  def complete_step(%__MODULE__{} = pipeline, %Step{} = step),
    do: %{pipeline | completed_steps: [step] ++ pipeline.completed_steps}

  def fail(%__MODULE__{} = pipeline),
    do: %{pipeline | failed?: true}
end
