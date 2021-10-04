{ mkDerivation, fetchurl }:

mkDerivation rec {
  version = "24.1";
  # nix-prefetch-url --unpack https://github.com/erlang/otp/archive/OTP-24.0.5.tar.gz
  sha256 = "1zxiqilnjrja2ihrsnpzlz2achkws1b7dnliw5qnzvz2sn9gf6fx";
}
