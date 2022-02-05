alias ExIntegrate, as: EI
alias ExIntegrate.Boundary.PipelineRunner
alias ExIntegrate.Boundary.RunManager
alias ExIntegrate.Boundary.Server, as: EIServer
alias ExIntegrate.Boundary.StepRunner
alias ExIntegrate.Core.Pipeline
alias ExIntegrate.Core.Run
alias ExIntegrate.Core.Step

# parse example configs into memory for convenience
run = "ei.json" |> File.read!() |> Jason.decode!() |> Run.new()
failing_run = "test/fixtures/fail.json" |> File.read!() |> Jason.decode!() |> Run.new()

failing_dependent_run =
  "test/fixtures/fail_dependent.json" |> File.read!() |> Jason.decode!() |> Run.new()
