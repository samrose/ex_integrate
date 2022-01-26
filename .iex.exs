alias ExIntegrate, as: EI
alias ExIntegrate.Boundary.PipelineRunner
alias ExIntegrate.Boundary.RunManager
alias ExIntegrate.Boundary.Server, as: EIServer
alias ExIntegrate.Boundary.StepRunner
alias ExIntegrate.Core.Pipeline
alias ExIntegrate.Core.Run
alias ExIntegrate.Core.Step

# parse ei.json into memory for convenience
run =
  "ei.json"
  |> File.read!()
  |> Jason.decode!()
  |> Run.new()
