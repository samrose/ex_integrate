defmodule ExIntegrateTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias ExIntegrate.Step
  alias ExIntegrate.Config

  @config_fixture_path "test/fixtures/ei.test.json"

  describe "running the steps from a config file" do
    test "success: runs pipeline steps in order and returns :ok" do
      run_pipelines_from_file = fn ->
        assert {:ok, %Config{}} = ExIntegrate.run_pipelines_from_file(@config_fixture_path)
      end

      assert capture_io(run_pipelines_from_file) == "step 1\nstep 2\nstep 3\n"
    end

    test "when file doesn't exist, raises error" do
      assert_raise File.Error,
                   fn -> ExIntegrate.run_pipelines_from_file("nonexistant_file") end
    end
  end

  describe "touching a tmp file" do
    setup :create_tmp_dir

    test "success: creates the file", %{tmp_dir_path: tmp_dir_path} do
      path = Path.join([tmp_dir_path, "ei_test.txt"])
      step = Step.new(%{"name" => "create_tmp_file", "command" => "touch", "args" => [path]})
      assert {:ok, _} = ExIntegrate.run_step(step)
      assert {:ok, _} = File.read(path)
    end

    defp create_tmp_dir(_context) do
      tmp_dir_path = Path.join([System.tmp_dir!(), "ei_test"])
      File.mkdir!(tmp_dir_path)
      on_exit(fn -> File.rm_rf!(tmp_dir_path) end)

      [tmp_dir_path: tmp_dir_path]
    end
  end
end
