{ lib, stdenv, buildGoModule, fetchFromGitHub, libobjc, IOKit }:

let

in buildGoModule rec {
  pname = "heimdall-polygon";
  version = "1.0.7";

  src = fetchFromGitHub {
    owner = "maticnetwork";
    repo = "heimdall";
    rev = "v${version}";
    sha256 = "sha256-uDcY1asIsX1Jut6R/g9JAFTdjlixFHiCpt9NSalMg/o="; # retrieved using nix-prefetch-url
  };

  proxyVendor = true;
  vendorHash = "sha256-am1x7Mdm2yuWZxNMAF5LMuCwA2fofck0w/QKnxIyQd8=";

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
    description = "Heimdall is an Ethereum-compatible sidechain for the Polygon network";
    homepage = "https://github.com/maticnetwork/heimdall";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}