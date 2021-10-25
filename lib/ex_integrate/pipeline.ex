defmodule ExIntegrate.Piepline do
  alias ExIntegrate.Step

  @type t :: %__MODULE__{
    steps: [Step.t()]
  }

  defstruct [:steps]
end
