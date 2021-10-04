{ pkgs ? import ./nixpkgs.nix {} }:

with pkgs;
let
  inherit (lib) optional optionals;

  erlang = pkgs.beam.lib.callErlang ./erlang.nix {};

  elixir = pkgs.beam.lib.callElixir ./elixir.nix {
    inherit erlang;
    debugInfo = true;
  };

  elixir-erlang-src = runCommand "elixir-erlang-src" {} ''
    mkdir $out
    ln -s ${elixir.src} $out/elixir
    ln -s ${erlang.src} $out/otp
  '';#used for vim configs
in

mkShell {
  buildInputs = [ erlang elixir ]
    ++ optional stdenv.isLinux inotify-tools
    ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
      # For file_system on macOS.
      CoreFoundation
      CoreServices
    ]);

  shellHook = ''
    export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
  '';

}

