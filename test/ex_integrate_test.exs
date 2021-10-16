defmodule ExIntegrateTest do
  use ExUnit.Case
  doctest ExIntegrate

  @config_fixture_path "test/fixtures/ei.test.json"

  describe "running the steps" do
    test "success: returns :ok" do
      assert :ok = ExIntegrate.run_steps(@config_fixture_path)
    end

    for invalid_input <- [123, :not_a_string, nil] do
      test "rejects non-binary input for #{invalid_input}" do
        assert_raise FunctionClauseError, fn ->
          invalid_input = Macro.escape(unquote(invalid_input))
          ExIntegrate.run_steps(invalid_input)
        end
      end
    end
  end
end
