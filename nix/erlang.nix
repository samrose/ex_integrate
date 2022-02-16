{ mkDerivation, fetchurl }:

mkDerivation rec {
  version = "24.2";
  # nix-prefetch-url --unpack https://github.com/erlang/otp/archive/OTP-${version}.tar.gz
  sha256 = "10s57v2i2qqyg3gddm85n3crzrkikl4zfwgzqmxjzdynsyb4xg68";
}
