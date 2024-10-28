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

      clerk_poll_interval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Set clerk poll interval.";
      };

      eth_rpc_url = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:8545";
        description = "Set RPC endpoint for Ethereum chain.";
      };

      heimdall_config = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Override Heimdall config file.";
      };

      logs_writer_file = lib.mkOption {
        type = lib.types.str;
        default = "os.Stdout";
        description = "Set logs writer file. Default is os.Stdout.";
      };

      main_chain_gas_limit = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Set main chain gas limit.";
      };

      main_chain_max_gas_price = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Set main chain max gas price.";
      };

      milestone_poll_interval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Set milestone interval.";
      };

      no_ack_wait_time = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Set time ack service waits to clear buffer.";
      };

      seeds = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Override seeds.";
      };

      trace = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Print out full stack trace on errors.";
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
      description = "Specification of one or more Heimdall node instances.";
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
              start \
              --home ${dataDir} \
              --chain ${cfg.chain} \
              --amqp_url ${cfg.amqp_url} \
              --bor_rpc_url ${cfg.bor_rpc_url} \
              --checkpoint_poll_interval ${cfg.checkpoint_poll_interval} \
              --clerk_poll_interval ${cfg.clerk_poll_interval} \
              --eth_rpc_url ${cfg.eth_rpc_url} \
              ${lib.optionalString (cfg.heimdall_config != null) "--heimdall-config ${cfg.heimdall_config}"} \
              --logs_writer_file ${cfg.logs_writer_file} \
              ${lib.optionalString (cfg.main_chain_gas_limit != null) "--main_chain_gas_limit ${toString cfg.main_chain_gas_limit}"} \
              ${lib.optionalString (cfg.main_chain_max_gas_price != null) "--main_chain_max_gas_price ${toString cfg.main_chain_max_gas_price}"} \
              --milestone_poll_interval ${cfg.milestone_poll_interval} \
              ${lib.optionalString (cfg.no_ack_wait_time != null) "--no_ack_wait_time ${cfg.no_ack_wait_time}"} \
              ${lib.optionalString (cfg.seeds != null) "--seeds ${cfg.seeds}"} \
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