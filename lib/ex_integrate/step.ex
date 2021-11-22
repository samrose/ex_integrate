defmodule ExIntegrate.Core.Step do
  @moduledoc """
  Represents a step in the CI pipeline. 
  """

  @enforce_keys [:name, :command, :args]

  defstruct [
    :args,
    :command,
    :name,
    err: nil,
    out: nil,
    status_code: nil
  ]

  @type t :: %__MODULE__{
          args: [String.t()],
          command: :String.t(),
          err: String.t(),
          name: String.t(),
          out: String.t(),
          status_code: non_neg_integer
        }

  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      args: attrs["args"],
      command: attrs["command"],
      name: attrs["name"]
    }
  end

  def save_results(%__MODULE__{} = step, status_code, out, err) do
    %{step | status_code: status_code, out: out, err: err}
  end

  def failed?(%__MODULE__{} = step) do
    step.status_code !== 0 and not is_nil(step.status_code)
  end
end
