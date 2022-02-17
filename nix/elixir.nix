{ mkDerivation }:

mkDerivation rec {
  version = "1.13.2";

  # nix-prefetch-url --unpack https://github.com/elixir-lang/elixir/archive/v${version}.tar.gz
  sha256 = "sha256-qv85aDP3RPCa1YBo45ykWRRZNanL6brNKDMPu9SZdbQ=";
  minimumOTPVersion = "23";
}

