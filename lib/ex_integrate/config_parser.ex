defmodule ExIntegrate.Boundary.ConfigParser do
  def import_json(filename) when is_binary(filename) do
    filename
    |> File.read!()
    |> Jason.decode!()
  end
end
