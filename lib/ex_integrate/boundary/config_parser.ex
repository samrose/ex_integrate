defmodule ExIntegrate.Boundary.ConfigParser do
  @moduledoc """
  Validates and parses the user config file.
  """
  def import_json(filename) when is_binary(filename) do
    filename
    |> File.read!()
    |> Jason.decode!()
  end
end
