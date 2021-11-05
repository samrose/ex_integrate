defmodule ExIntegrate.Step do
  @moduledoc """
  Represents a step in the CI pipeline. 
  """

  defmodule Error do
    defexception [:message, :reason]
  end

  @enforce_keys [:name, :command, :args]

  defstruct [
    :args,
    :command,
    :name,
    err: nil,
    out: nil,
    status: :not_run
  ]

  @type t :: %__MODULE__{
          args: [String.t()],
          command: :String.t(),
          name: String.t(),
          status: atom,
          err: String.t(),
          out: String.t()
        }

  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      args: attrs["args"],
      command: attrs["command"],
      name: attrs["name"]
    }
  end
end
