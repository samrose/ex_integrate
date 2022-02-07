{ sources ? import ./nix/sources.nix }:
let
  pkgs = import sources.nixpkgs { };
  inputs = [
    pkgs.cmake
    pkgs.erlang
    pkgs.elixir
    pkgs.inotify-tools
  ];
in

pkgs.mkShell {
  buildInputs = inputs;
  shellHook = ''
    export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
  '';

}
