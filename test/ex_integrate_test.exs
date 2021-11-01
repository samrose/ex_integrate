defmodule ExIntegrateTest do
  use ExUnit.Case
  doctest ExIntegrate
  alias ExIntegrate.Step

  @config_fixture_path "test/fixtures/ei.test.json"

  describe "running the steps" do
    test "success: returns :ok" do
      assert :error = ExIntegrate.run_pipelines(@config_fixture_path)
    end

    test "when file doesn't exist, raises error" do
      assert_raise File.Error,
                   fn -> ExIntegrate.run_pipelines("nonexistant_file") end
    end

    for invalid_input <- [123, :not_a_string, nil] do
      test "rejects non-binary input for #{invalid_input}" do
        assert_raise FunctionClauseError, fn ->
          invalid_input = Macro.escape(unquote(invalid_input))
          ExIntegrate.run_pipelines(invalid_input)
        end
      end
    end
  end

  describe "touching a tmp file" do
    setup do
      tmp_dir_path = Path.join([System.tmp_dir!(), "ei_test"])
      File.mkdir!(tmp_dir_path)
      on_exit(fn -> File.rm_rf!(tmp_dir_path) end)

      {:ok, tmp_dir_path: tmp_dir_path}
    end

    test "success: creates the file", %{tmp_dir_path: tmp_dir_path} do
      path = Path.join([tmp_dir_path, "ei_test.txt"])
      step = Step.new(%{"name" => "create_tmp_file", "command" => "touch", "args" => [path]})
      assert {:ok, _} = ExIntegrate.run_step(step)
      assert {:ok, _} = File.read(path)
    end
  end
end
