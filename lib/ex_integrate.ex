defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  def run_steps(filename) when is_binary(filename) do
    steps =
      filename
      |> File.read!()
      |> Jason.decode!()

    steps
    |> Map.get("steps")
    |> Enum.each(fn x ->
      path = System.find_executable(x["command"])
      Rambo.run(path, x["args"], log: true)
    end)
  end
end
