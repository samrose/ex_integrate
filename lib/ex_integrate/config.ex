defmodule ExIntegrate.Config do
  alias ExIntegrate.Pipeline
  alias ExIntegrate.Step

  defstruct [:pipelines]

  @type t :: %__MODULE__{
    pipelines: [Pipeline.t()]
  }

  @spec new(attrs :: map) :: t()
  def new(attrs) do
    pipelines =
      attrs
      |> Access.get("pipelines", [])
      |> Enum.map(fn pipeline_attrs ->
        steps = Enum.map(pipeline_attrs["steps"], &Step.new/1)
        %Pipeline{steps: steps}
      end)

    %__MODULE__{pipelines: pipelines}
  end
end
