defmodule ExIntegrate.Core.Step do
  @moduledoc """
  Represents a single unit of work in the CI pipeline. Steps run sequentially
  inside Pipelines.

  A step stores data specifying what is to be executed as well as data about the
  result of command execution. It has a unique `name`, a `command`, and
  multiple `args`.

  Note that the `name` must be unique, as it is used internally as a unique key
  to identify steps.
  """

  @enforce_keys [:name, :command, :args]
  defstruct @enforce_keys ++ [:err, :out, :status_code]

  @type t :: %__MODULE__{
          args: [String.t()],
          command: :String.t(),
          err: String.t(),
          name: String.t(),
          out: String.t(),
          status_code: non_neg_integer
        }

  def new(attrs) do
    %__MODULE__{
      args: attrs[:args] || attrs["args"],
      command: attrs[:command] || attrs["command"],
      name: attrs[:name] || attrs["name"]
    }
  end

  def save_results(%__MODULE__{} = step, status_code, out, err),
    do: %{step | status_code: status_code, out: out, err: err}

  def failed?(%__MODULE__{} = step),
    do: is_integer(step.status_code) and step.status_code !== 0
end
