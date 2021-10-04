{ mkDerivation }:

mkDerivation rec {
  version = "1.12.3";

  # nixnix-prefetch-url --unpack https://github.com/elixir-lang/elixir/archive/v1.12.3.tar.gz
  sha256 = "07fisdx755cgyghwy95gvdds38sh138z56biariml18jjw5mk3r6";
  minimumOTPVersion = "24";
}
