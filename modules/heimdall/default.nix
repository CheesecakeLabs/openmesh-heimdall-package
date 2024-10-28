{ config, lib, pkgs, ... }:

let
  eachHeimdall = config.services.heimdall-polygon;

  heimdallOpts = { config, lib, name, ... }: {
    options = {
      enable = lib.mkEnableOption "Polygon Heimdall Node";

      chain = lib.mkOption {
        type = lib.types.str;
        default = "mainnet";
        description = "Set one of the chains: [mainnet, mumbai, amoy, local].";
      };

      amqp_url = lib.mkOption {
        type = lib.types.str;
        default = "amqp://guest:guest@localhost:5672/";
        description = "Set AMQP endpoint.";
      };

      bor_rpc_url = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:8545";
        description = "Set RPC endpoint for the Bor chain.";
      };

      checkpoint_poll_interval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Set checkpoint poll interval.";
      };

      logs_writer_file = lib.mkOption {
        type = lib.types.str;
        default = "os.Stdout";
        description = "Set logs writer file. Default is os.Stdout.";
      };

      trace = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable detailed logging with full stack traces.";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional arguments for the Heimdall executable.";
      };

      package = lib.mkPackageOption pkgs [ "heimdall-polygon" ] { };
    };
  };

in {
  ###### Interface
  options = {
    services.heimdall-polygon = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule heimdallOpts);
      default = {};
      description = "Configuration for Heimdall Polygon nodes.";
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

        serviceConfig = {
          ExecStart = ''
            ${cfg.package}/bin/heimdalld start \
              --home ${dataDir} \
              --chain ${cfg.chain} \
              --amqp_url ${cfg.amqp_url} \
              --bor_rpc_url ${cfg.bor_rpc_url} \
              --checkpoint_poll_interval ${cfg.checkpoint_poll_interval} \
              --logs_writer_file ${cfg.logs_writer_file} \
              ${lib.optionalString cfg.trace "--trace"} \
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