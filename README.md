# ExIntegrate

![CircleCI](https://img.shields.io/circleci/build/github/samrose/ex_integrate)

*Note: this project is under construction and not yet ready for public use*

A Continuous Integration (CI) library written in Elixir. ExIntegrate leverages
the concurrency and fault-tolerance of the BEAM to deliver fast, flexible
builds.


## About

ExIntegrate is a continuous integration system composed of two OTP applications: 
ExIntegrate Core and ExIntegrate Server. _This repository contains the code for 
ExIntegrate Core_. 

ExIntegrate Core plays the role of a CI runner. As the system design diagram below 
demonstrates, all CI runs happen within ExIntegrate Core, while 
all external interactions take place in ExIntegrate Server.

![20220301_ex_integrate_system_design](https://user-images.githubusercontent.com/45802549/156200951-124900e7-8fff-44a1-bdcc-f793ea64365d.svg)

### Main Concepts

* ExIntegrate allows the user to define and compose a series of system commands 
to execute. 

* In ExIntegrate, each command is called a __Step__: a single unit of 
work in the CI flow. Steps run sequentially inside Pipelines, and Pipelines run 
concurrently inside Runs. A step stores data specifying what is to be executed 
as well as data about the result of command execution. It has a unique `name`, 
a `command`, and multiple `args`.

* A __Pipeline__ is a series of Steps, run sequentially.

* A __Run__ consists of many Pipelines, which it runs in parallel except when they
depend on each other. A Run represents an entire CI orchestrated workflow, 
from start to finish. (Internally, a run's pipelines are stored in a directed
acyclic graph (DAG) which is traversed as pipelines are launched and completed.)

* This repository is split into two namespaces: `Core` and `Boundary`. `Core` comprises the functional core of the application and defines data structures and functions that operate on them. `Boundary` comprises the boundary layer which deals with IO, process architecture, and side effects. All OTP code is in the `Boundary` layer.

* ExIntegrate Core uses OTP to manage the lifecycle, concurrency, and fault-tolerance of a run.
The basic message passing and lifecycle is illustrated below:

![image](https://user-images.githubusercontent.com/115821/149588633-94a8c673-bfa9-4935-9e19-8555d73e3fb8.png)


## Getting Started

### Prerequisites

* Elixir 1.13+ (not yet tested on prior versions)
* Erlang/OTP 24+ (not yet tested on prior versions)

### Installation

Right now, the project must be cloned and built locally in order to use.

As we near our initial release goals, we will solidify a release strategy. Since
one of the project goals is to be able to easily replicate and run a CI server
on a local dev machine, we are currently exploring various release options that
will facilitate this flexibility.

Installation steps:

```sh
# Git clone this repository

# Enter the project directory
cd ex_integrate

# Create shell.nix with the example content below
touch shell.nix

# Enter a nix shell for the project
nix-shell

# Now that the environment is set up, we can run mix commands
mix compile
```

Example `shell.nix`:

```nix
# shell.nix
{ sources ? import ./nix/sources.nix }:

with import sources.nixpkgs { };
let
  erlang = beam.lib.callErlang ./nix/erlang.nix {};

  elixir = beam.lib.callElixir ./nix/elixir.nix {
    inherit erlang;
    debugInfo = true;
  };

  basePackages = [
    cmake
    erlang
    elixir
  ];

  inputs = basePackages
    ++ lib.optionals stdenv.isLinux inotify-tools
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    # For file_system on macOS.
    CoreFoundation
    CoreServices
  ]);

  hooks = ''
    export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
    mkdir -p .nix-mix
    mkdir -p .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-hex
    export PATH=$MIX_HOME/bin:$PATH
    export PATH=$HEX_HOME/bin:$PATH
    export LANG=en_US.UTF-8
    export ERL_AFLAGS="-kernel shell_history enabled"
  '';

in
mkShell {
  buildInputs = inputs;
  shellHook = hooks;
}
```

## Usage

### As Mix Task

Right now the only usage of ExIntegrate is as a Mix Task. We plan to support a
number of other usages in the future as the core development work stabilizes. 

```sh
# reads ./ei.json by default
$ mix ei

# optionally specify a path
$ mix ei PATH_TO_CONFIG_JSON
```

### Defining a project configuration in `ei.json`

ExIntegrate follows the "configuration as code" philosophy and expects to see a
project configuration file in the source repo. Curently, only JSON is supported
for the config format, but we have discussed adding other formats later. 

For an example config file, see the project's own
[ei.json](https://github.com/samrose/ex_integrate/blob/master/ei.json).


## Roadmap

See the [open issues](https://github.com/samrose/ex_integrate/issues)
for a list of proposed features (and known issues).


## Authors

This project is authored by Sam Rose (@samrose) and Garrett George (@garrettmichaelgeorge).


## License

This project is licensed under the [Apache License Version
2.0](https://github.com/samrose/ex_integrate/blob/master/LICENSE).


## Acknowledgments

We are indebted to much of the prior art in the CI space for conceptual
foundation for this project, particularly GoCD, Drone.io, CircleCI, GitLab, and
GitHub Actions, among others. Many ideas came from Martin Fowler's ["Continuous
Integration"](https://martinfowler.com/articles/continuousIntegration.html)
article.
