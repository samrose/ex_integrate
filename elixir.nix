{ mkDerivation }:

mkDerivation rec {
  version = "1.13.0";

  # nixnix-prefetch-url --unpack https://github.com/elixir-lang/elixir/archive/v1.13.0.tar.gz
  sha256 = "1rkrx9kbs2nhkmzydm02r4wkb8wxwmg8iv0nqilpzj0skkxd6k8w";
  minimumOTPVersion = "24";
}
