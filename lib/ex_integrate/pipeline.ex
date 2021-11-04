defmodule ExIntegrate.Pipeline do
  alias ExIntegrate.Step

  @type t :: %__MODULE__{
    steps: [Step.t()]
  }

  defstruct [:steps]
end
