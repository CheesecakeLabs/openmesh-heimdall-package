{ lib, stdenv, buildGoModule, fetchFromGitHub, libobjc, IOKit }:

let

in buildGoModule rec {
  pname = "polygon-heimdall";
  version = "1.0.10";

  src = fetchFromGitHub {
    owner = "maticnetwork";
    repo = "heimdall";
    rev = "v${version}";
    sha256 = "sha256-CW7Od495CFfLl0e8TBKBs4FxBWWJqW7TkWHE/iDAejo="; # retrieved using nix-prefetch-url
  };

  proxyVendor = true;
  vendorHash = "sha256-KulHakuchEENNTgWxYR/c+OOla7aK9TSm7oToGgVyBs=";

  doCheck = false;

  outputs = [ "out" ];

  # Build using the new command
  buildPhase = ''
    mkdir -p $GOPATH/bin
    go build -o $GOPATH/bin/heimdalld ./cmd/heimdalld
    go build -o $GOPATH/bin/heimdallcli ./cmd/heimdallcli
  '';

  # Copy the built binary to the output directory
  installPhase = ''
    mkdir -p $out/bin
    cp $GOPATH/bin/heimdalld $out/bin/heimdalld
    cp $GOPATH/bin/heimdallcli $out/bin/heimdallcli
  '';

  # Fix for usb-related segmentation faults on darwin
  propagatedBuildInputs =
    lib.optionals stdenv.isDarwin [ libobjc IOKit ];

  meta = with lib; {
    mainProgram = "heimdalld";
    description = "Heimdall is an Ethereum-compatible sidechain for the Polygon network";
    homepage = "https://github.com/maticnetwork/heimdall";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}