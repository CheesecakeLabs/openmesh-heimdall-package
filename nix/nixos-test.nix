{ pkgs, system, ... }:
let
  testing = import "${toString pkgs.path}/nixos/lib/testing-python.nix" { inherit system pkgs; };
in
testing.makeTest {
  name = "polygon-heimdall";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ./nixos-module.nix ];
      services.polygon-heimdall = {
        enable = true;
      };
    };

  testScript = ''
    # Ensure the service is started and reachable
    machine.wait_for_unit("polygon-heimdall.service")
    machine.wait_for_open_port(1317)
    machine.succeed("curl --fail http://127.0.0.1:1317")
  '';
}