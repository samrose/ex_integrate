defmodule ExIntegrateTest do
  use ExUnit.Case
  doctest ExIntegrate

  @config_fixture_path "test/fixtures/ei.test.json"

  describe "running the steps" do
    test "success: returns :ok" do
      assert :ok = ExIntegrate.run_steps(@config_fixture_path)
    end
  end

  test "rejects non-binary input" do
    assert_raise FunctionClauseError, fn ->
      ExIntegrate.run_steps(123)
    end

    assert_raise FunctionClauseError, fn ->
      ExIntegrate.run_steps(:not_a_string)
    end

    assert_raise FunctionClauseError, fn ->
      ExIntegrate.run_steps(nil)
    end
  end
end
