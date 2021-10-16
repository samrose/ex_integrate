defmodule ExIntegrateTest do
  use ExUnit.Case
  doctest ExIntegrate

  @config_fixture_path "test/fixtures/ei.test.json"

  describe "running the steps" do
    test "success: returns :ok" do
      assert :ok = ExIntegrate.run_steps(@config_fixture_path)
    end
  end
end
