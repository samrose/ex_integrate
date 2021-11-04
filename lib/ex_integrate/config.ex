defmodule ExIntegrate.Config do
  alias ExIntegrate.Pipeline

  @type t :: %__MODULE__{
    pipelines: [Pipeline.t()]
  }

  defstruct [:pipelines]

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end
