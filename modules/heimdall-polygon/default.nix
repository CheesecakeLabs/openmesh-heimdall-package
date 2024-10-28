{ config, lib, pkgs, ... }:

let
  eachHeimdall = config.services.heimdall-polygon;

  heimdallOpts = { config, lib, name, ... }: {
    options = {
      enable = lib.mkEnableOption "Polygon Heimdall Node";

      chain-id = lib.mkOption {
        type = lib.types.int;
        default = 137;
        description = "Chain ID of the Polygon network (e.g., 137 for mainnet, 80001 for Mumbai testnet).";
      };

      datadir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/heimdall";
        description = "Path to the Heimdall data directory.";
      };

      rpc = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:1317";
          description = "Address for the RPC API.";
        };
      };

      grpc = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:9090";
          description = "Address for the gRPC API.";
        };
      };

      validator = lib.mkOption {
        type = lib.types.str;
        description = "Public address of the validator on the Polygon network.";
      };

      keystore = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/heimdall/keystore";
        description = "Path to the keystore directory containing the validator key.";
      };

      log-level = lib.mkOption {
        type = lib.types.str;
        default = "info";
        description = "Log level for Heimdall (trace|debug|info|warn|error|crit).";
      };

      seeds = lib.mkOption {
        type = lib.types.str;
        default = "seed1.polygon.io:26656,seed2.polygon.io:26656";
        description = "Seed nodes for connecting Heimdall to the Polygon network.";
      };

      snapshot = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable snapshot-database mode for fast sync.";
      };

      tx-index = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable transaction indexing.";
      };

      fast-sync = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable fast sync mode.";
      };

      verbosity = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Logging verbosity for Heimdall.";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional arguments for the Heimdall executable.";
      };

      package = lib.mkPackageOption pkgs [ "heimdall" ] { };
    };
  };

in {
  ###### Interface
  options = {
    services.heimdall-polygon = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule heimdallOpts);
      default = {};
      description = "Configuration for one or more Heimdall node instances.";
    };
  };

  ###### Implementation
  config = lib.mkIf (eachHeimdall != {}) {
    environment.systemPackages = lib.flatten (lib.mapAttrsToList (name: cfg: [
      cfg.package
    ]) eachHeimdall);

    systemd.services = lib.mapAttrs' (name: cfg: let
      stateDir = "polygon/heimdall/${name}";
      dataDir = "/var/lib/${stateDir}";
    in (
      lib.nameValuePair "heimdall-polygon-${name}" (lib.mkIf cfg.enable {
        description = "Polygon Heimdall Node (${name})";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          ExecStart = ''
            ${cfg.package}/bin/heimdalld \
              --datadir ${dataDir} \
              --chain-id ${toString cfg.chain-id} \
              --rpc.address ${cfg.rpc.address} \
              --grpc.address ${cfg.grpc.address} \
              ${lib.optionalString (cfg.validator != null) "--validator ${cfg.validator}"} \
              --keystore ${cfg.keystore} \
              --log-level ${cfg.log-level} \
              --seeds ${cfg.seeds} \
              ${lib.optionalString cfg.snapshot "--snapshot"} \
              ${lib.optionalString cfg.tx-index "--tx-index"} \
              ${lib.optionalString cfg.fast-sync "--fast-sync"} \
              --verbosity ${toString cfg.verbosity} \
              ${lib.escapeShellArgs cfg.extraArgs}
          '';
          DynamicUser = true;
          Restart = "always";
          RestartSec = 5;
          StateDirectory = stateDir;

          # Hardening options
          PrivateTmp = true;
          ProtectSystem = "full";
          NoNewPrivileges = true;
          PrivateDevices = true;
          MemoryDenyWriteExecute = true;
          StandardOutput = "journal";
          StandardError = "journal";
          User = "heimdall";
        };
      })
    )) eachHeimdall;
  };
}