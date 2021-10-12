defmodule ExIntegrate do
  @moduledoc """
  Documentation for `ExIntegrate`.
  """

  def run_steps(file) do
    steps = Jason.decode!(File.read!(file))
    steps
    |> Map.get("steps")
    |> Enum.each(fn x->
        path = System.find_executable(x["command"])
        Rambo.run(path,x["args"], log: true)
    end)
  end
end
