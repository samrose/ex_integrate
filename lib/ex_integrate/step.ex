defmodule ExIntegrate.Step do
  @moduledoc """
  Represents a step in the CI pipeline. 
  """

  defmodule Error do
    defexception [:message, :reason]
  end

  @enforce_keys [:name, :command]
  defstruct [:name, :command, args: [], command_data: nil]

  @type t :: %__MODULE__{
          args: [String.t()],
          command: :String.t(),
          command_data: Rambo.t(),
          name: String.t()
        }

  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      args: attrs["args"],
      command: attrs["command"],
      name: attrs["name"]
    }
  end
end
