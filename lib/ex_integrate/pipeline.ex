defmodule ExIntegrate.Pipeline do
  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner

  @type t :: %__MODULE__{
          steps: [Step.t()]
        }

  defstruct [:steps]

  def run(%__MODULE__{} = pipeline) do
    pipeline_task =
      Task.async(fn ->
        Enum.each(pipeline.steps, &StepRunner.run_step/1)
      end)

    Task.await(pipeline_task)
  end
end
