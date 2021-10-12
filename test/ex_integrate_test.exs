defmodule ExIntegrateTest do
  use ExUnit.Case
  doctest ExIntegrate

  test "run steps" do
    assert ExIntegrate.run_steps("test/ei.test.json") == :ok
  end
end
