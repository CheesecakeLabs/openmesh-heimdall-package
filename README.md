# Polygon Heimdall NixOS Module

This NixOS module allows you to easily set up and run a Polygon Heimdall node using systemd. Heimdall is a core component of the Polygon network, responsible for consensus and other blockchain functionalities. This README provides instructions on configuring and running the Heimdall node with this NixOS module.

## Features

- Supports multiple chains: `mainnet`, `mumbai`, `amoy`, and `local`.
- Fully configurable RPC URLs for Bor, Eth, and Tendermint chains.
- REST server support for the Heimdall chain.
- Configurable seed nodes.
- Additional arguments support for Heimdall.
- Hardened systemd configuration.

## Installation

1. Add the flake to your NixOS `flake.nix` file (usually stored in `/etc/nixos/flake.nix`).

   ```nix
   {
     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
       # Add the polygon-heimdall flake
       polygon-heimdall.url = "github:CheesecakeLabs/polygon-heimdall-nix";
     };

     outputs = { self, nixpkgs, polygon-heimdall }: {
       nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         modules = [
           ./path/to/your/configuration.nix
           # Include the polygon-heimdall module
           polygon-heimdall.nixosModules.polygon-heimdall
         ];
       };
     };
   }
   ```

2. Enable the service and configure the desired options in your `configuration.nix` (usually stored in `/etc/nixos/configuration.nix`).

   ```nix
   services.polygon-heimdall = {
      enable = true;
      chain = "mainnet";
   };
   ```

3. Apply your configuration:

   ```bash
   sudo nixos-rebuild switch
   ```

## Configuration Options

| Option                 | Type       | Default                        | Description                                                          |
| ---------------------- | ---------- | ------------------------------ | -------------------------------------------------------------------- |
| `enable`               | boolean    | `false`                        | Enable the Polygon Heimdall service.                                 |
| `chain`                | string     | `mainnet`                      | Set the chain to use. Options: `mainnet`, `mumbai`, `amoy`, `local`. |
| `bor_rpc_url`          | string     | `http://0.0.0.0:8545`          | RPC endpoint for the Bor chain.                                      |
| `eth_rpc_url`          | string     | `http://0.0.0.0:9545`          | RPC endpoint for the Ethereum chain.                                 |
| `tendermint_rpc_url`   | string     | `http://0.0.0.0:26657`         | RPC endpoint for the Tendermint chain.                               |
| `heimdall_rest_server` | string     | `http://0.0.0.0:1317`          | REST server for the Heimdall chain.                                  |
| `extraArgs`            | listOf str | `[]`                           | Additional arguments for the Heimdall executable.                    |
| `seeds`                | string     | List of predefined seed nodes. | Seed nodes for network connectivity.                                 |

## Firewall Configuration

The module automatically configures the following ports in the NixOS firewall:

- **TCP Ports:** 30303, 8545, 8546, 8547, 9091, 3001, 7071, 30301, 26656, 1317
- **UDP Ports:** 30303, 8545, 8546, 8547, 9091, 3001, 7071, 30301, 26656, 1317

## Systemd Service

The Heimdall node is managed as a systemd service with the following features:

- Automatically restarts on failure.
- Runs in a hardened environment with limited privileges.
- Logs output to the system journal.

### Service Configuration

The service uses the following configuration:

- **ExecStart:** Runs the Heimdall executable with the provided options.
- **DynamicUser:** Ensures the service runs as a non-root user.
- **Hardening:** Includes `PrivateTmp`, `ProtectSystem`, `NoNewPrivileges`, and other settings to enhance security.
- **State Directory:** Stores data under `/var/lib/polygon/heimdall/<chain>`.

## Example Usage

Here's a complete example of configuring the service for the `mumbai` testnet:

```nix
services.polygon-heimdall = {
  enable = true;
  chain = "mumbai";
  bor_rpc_url = "http://127.0.0.1:8545";
  eth_rpc_url = "http://127.0.0.1:9545";
  tendermint_rpc_url = "http://127.0.0.1:26657";
  heimdall_rest_server = "http://127.0.0.1:1317";
  seeds = "1500161dd491b67fb1ac81868952be49e2509c9f@52.78.36.216:26656";
  extraArgs = ["--verbose"];
};
```

## Troubleshooting

- **Service Logs:** Check the logs using `journalctl`.

  ```bash
  journalctl -u polygon-heimdall.service
  ```

- **Configuration Errors:** Ensure all required options are correctly configured in your `configuration.nix` file.
- **Connectivity Issues:** Verify that the seed nodes and RPC URLs are accessible.

---

Happy staking with Polygon Heimdall!
