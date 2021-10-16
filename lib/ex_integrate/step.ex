defmodule ExIntegrate.Step do
  @moduledoc """
  Represents a step in the CI pipeline. 
  """

  @enforce_keys [:name, :command]
  defstruct [:name, :command, args: []]

  @type t :: %__MODULE__{
          name: String.t(),
          command: :String.t(),
          args: [String.t()]
        }

  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      args: attrs["args"],
      command: attrs["command"],
      name: attrs["name"]
    }
  end
end
