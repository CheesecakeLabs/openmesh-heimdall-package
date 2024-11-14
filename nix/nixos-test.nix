{ pkgs }:

pkgs.nixosTest {
  name = "polygon-heimdall";

  nodes.machine =
    { config, pkgs, ... }:
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
    machine.succeed("curl --fail http://localhost:1317/status")
  '';
}