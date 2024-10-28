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
        description = "Set AMQP endpoint.";
      };

      bor_rpc_url = lib.mkOption {
        type = lib.types.str;
        description = "Set RPC endpoint for the Bor chain.";
      };

      checkpoint_poll_interval = lib.mkOption {
        type = lib.types.str;
        description = "Set checkpoint poll interval.";
      };

      clerk_poll_interval = lib.mkOption {
        type = lib.types.str;
        description = "Set clerk poll interval.";
      };

      eth_rpc_url = lib.mkOption {
        type = lib.types.str;
        description = "Set RPC endpoint for Ethereum chain.";
      };

      heimdall_config = lib.mkOption {
        type = lib.types.path;
        description = "Override Heimdall config file.";
      };

      heimdall_rest_server = lib.mkOption {
        type = lib.types.str;
        description = "Set Heimdall REST server endpoint.";
      };

      logs_writer_file = lib.mkOption {
        type = lib.types.str;
        description = "Set logs writer file. Default is os.Stdout.";
      };

      main_chain_gas_limit = lib.mkOption {
        type = lib.types.int;
        description = "Set main chain gas limit.";
      };

      main_chain_max_gas_price = lib.mkOption {
        type = lib.types.int;
        description = "Set main chain max gas price.";
      };

      milestone_poll_interval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Set milestone interval.";
      };

      no_ack_wait_time = lib.mkOption {
        type = lib.types.str;
        description = "Set time ack service waits to clear buffer.";
      };

      noack_poll_interval = lib.mkOption {
        type = lib.types.str;
        description = "Set no acknowledge poll interval.";
      };

      span_poll_interval = lib.mkOption {
        type = lib.types.str;
        description = "Set span poll interval.";
      };

      syncer_poll_interval = lib.mkOption {
        type = lib.types.str;
        description = "Set syncer poll interval.";
      };

      tendermint_rpc_url = lib.mkOption {
        type = lib.types.str;
        description = "Set RPC endpoint for Tendermint.";
      };

      trace = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Print out full stack trace on errors.";
      };

      seeds = lib.mkOption {
        type = lib.types.str;
        description = "Override seeds.";
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
            ${cfg.package}/bin/heimdalld start \
              --home ${dataDir} \
              --chain ${cfg.chain} \
              ${lib.optionalString (cfg.amqp_url != null) "--amqp_url ${cfg.amqp_url}"} \
              ${lib.optionalString (cfg.bor_rpc_url != null) "--bor_rpc_url ${cfg.bor_rpc_url}"} \
              ${lib.optionalString (cfg.checkpoint_poll_interval != null) "--checkpoint_poll_interval ${cfg.checkpoint_poll_interval}"} \
              ${lib.optionalString (cfg.clerk_poll_interval != null) "--clerk_poll_interval ${cfg.clerk_poll_interval}"} \
              ${lib.optionalString (cfg.eth_rpc_url != null) "--eth_rpc_url ${cfg.eth_rpc_url}"} \
              ${lib.optionalString (cfg.heimdall_config != null) "--heimdall-config ${cfg.heimdall_config}"} \
              ${lib.optionalString (cfg.heimdall_rest_server != null) "--heimdall_rest_server ${cfg.heimdall_rest_server}"} \
              ${lib.optionalString (cfg.logs_writer_file != null) "--logs_writer_file ${cfg.logs_writer_file}"} \
              ${lib.optionalString (cfg.main_chain_gas_limit != null) "--main_chain_gas_limit ${toString cfg.main_chain_gas_limit}"} \
              ${lib.optionalString (cfg.main_chain_max_gas_price != null) "--main_chain_max_gas_price ${toString cfg.main_chain_max_gas_price}"} \
              ${lib.optionalString (cfg.milestone_poll_interval != null) "--milestone_poll_interval ${cfg.milestone_poll_interval}"} \
              ${lib.optionalString (cfg.no_ack_wait_time != null) "--no_ack_wait_time ${cfg.no_ack_wait_time}"} \
              ${lib.optionalString (cfg.noack_poll_interval != null) "--noack_poll_interval ${cfg.noack_poll_interval}"} \
              ${lib.optionalString (cfg.span_poll_interval != null) "--span_poll_interval ${cfg.span_poll_interval}"} \
              ${lib.optionalString (cfg.syncer_poll_interval != null) "--syncer_poll_interval ${cfg.syncer_poll_interval}"} \
              ${lib.optionalString (cfg.tendermint_rpc_url != null) "--tendermint_rpc_url ${cfg.tendermint_rpc_url}"} \
              ${lib.optionalString cfg.trace "--trace"} \
              ${lib.optionalString (cfg.seeds != null) "--seeds ${cfg.seeds}"}
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