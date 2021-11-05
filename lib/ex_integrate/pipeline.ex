defmodule ExIntegrate.Pipeline do
  alias ExIntegrate.Step
  alias ExIntegrate.StepRunner

  @type t :: %__MODULE__{
          steps: [Step.t()]
        }

  defstruct [:steps, :failed?]

  def run(%__MODULE__{} = pipeline) do
    pipeline_task =
      Task.async(fn ->
        Enum.map(pipeline.steps, &StepRunner.run_step/1)
      end)

    results = Task.await(pipeline_task)

    if Enum.any?(results, &failed_step?/1) do
      %{pipeline | failed?: true}
    else
      %{pipeline | failed?: false}
    end
  end

  defp failed_step?(step_result) do
    match?({:error, _}, step_result)
  end
end
