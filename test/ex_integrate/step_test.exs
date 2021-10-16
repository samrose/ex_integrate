defmodule ExIntegrate.StepTest do
  use ExUnit.Case, async: true

  alias ExIntegrate.Step

  test "create step from user input" do
    step_attrs = %{
      "name" => "test",
      "command" => "echo",
      "args" => ["TEST"]
    }

    assert %Step{} = step = Step.new(step_attrs)

    for {attr, val} <- Map.to_list(step_attrs) do
      attr = String.to_existing_atom(attr)
      assert Map.fetch!(step, attr) == val
    end
  end
end
