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
    status_code: nil
  ]

  @type t :: %__MODULE__{
          args: [String.t()],
          command: :String.t(),
          err: String.t(),
          name: String.t(),
          out: String.t(),
          status_code: non_neg_integer,
        }

  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      args: attrs["args"],
      command: attrs["command"],
      name: attrs["name"]
    }
  end
end
