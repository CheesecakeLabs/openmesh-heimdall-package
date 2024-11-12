{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.polygon-heimdall;
  polygon-heimdall = pkgs.callPackage ./package.nix {
    lib = pkgs.lib;
    stdenv = pkgs.stdenv;
    buildGoModule = pkgs.buildGoModule;
    fetchFromGitHub = pkgs.fetchFromGitHub;
    libobjc = pkgs.darwin.libobjc;
    IOKit = pkgs.darwin.IOKit;
  };
in
{
  options = {
    services.polygon-heimdall = {
      enable = lib.mkEnableOption "Polygon Heimdall Node";

      chain = lib.mkOption {
        type = lib.types.str;
        default = "mainnet";
        description = "Set one of the chains: [mainnet, mumbai, amoy, local].";
      };

      bor_rpc_url = lib.mkOption {
        type = lib.types.str;
        default = "localhost:8545";
        description = "Set RPC endpoint for the Bor chain.";
      };

      checkpoint_poll_interval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Set checkpoint poll interval.";
      };

      logs_writer_file = lib.mkOption {
        type = lib.types.str;
        default = null;
        description = "Set logs writer file. Default is os.Stdout.";
      };

      trace = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable detailed logging with full stack traces.";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional arguments for the Heimdall executable.";
      };

      seeds = lib.mkOption {
        type = lib.types.str;
        default = "1500161dd491b67fb1ac81868952be49e2509c9f@52.78.36.216:26656,dd4a3f1750af5765266231b9d8ac764599921736@3.36.224.80:26656,8ea4f592ad6cc38d7532aff418d1fb97052463af@34.240.245.39:26656,e772e1fb8c3492a9570a377a5eafdb1dc53cd778@54.194.245.5:26656,6726b826df45ac8e9afb4bdb2469c7771bd797f1@52.209.21.164:26656";
        description = "List of seeds to connect to.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.polygon-heimdall = {
      description = "Polygon Heimdall Node";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        ExecStart = ''
          ${polygon-heimdall}/bin/heimdalld start \
            --home "/var/lib/polygon/heimdall/${cfg.chain}" \
            --chain ${cfg.chain} \
            --bor_rpc_url ${cfg.bor_rpc_url} \
            --seeds ${cfg.seeds} \
            --checkpoint_poll_interval ${cfg.checkpoint_poll_interval} \
            ${lib.optionalString cfg.trace "--trace"} \
            ${lib.escapeShellArgs cfg.extraArgs}
        '';
        DynamicUser = true;
        Restart = "always";
        RestartSec = 5;
        StateDirectory = "polygon/heimdall/${cfg.chain}";

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
    };
  };
}