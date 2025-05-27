{ self }:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.satisfactory;
in
{
  options.services.northstar = {
    enable = lib.mkEnableOption "Northstar Dedicated Server";

    package-wine-env = lib.mkPackageOption pkgs "wine-env" { };
    package-nswrap = lib.mkPackageOption pkgs "nswrap" { };
    package-nswine-run = lib.mkPackageOption pkgs "nswine-run" { };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/northstar";
      description = "Directory to store the server state.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "northstar";
      description = "User to run the server as.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 37015;
      description = ''
        Override the Game Port the server uses.
      '';
    };

    openFirewall = lib.mkEnableOption "" // {
      description = "Whether to open the ports in the firewall.";
    };

    settings = lib.mkOption {
      description = "Northstar and Titanfall 2 common settings";
      default = { };
      type = lib.types.submodule {
        options = {
          password = lib.mkOption {
            description = "Specifies the password used by northstar.";
            type = lib.types.string;
            default = "";
          };
          passwordFile = lib.mkOption {
            description = "Specifies the password used by northstar using a file.";
            type = lib.types.path;
            default = null;
          };
          name = lib.mkOption {
            description = "Specifies the name of the server.";
            type = lib.types.string;
            default = "Unnamed Flake Northstar Server";
          };
          description = lib.mkOption {
            description = "Specifies the description of the server.";
            type = lib.types.string;
            default = "Default server description";
          };
        };
      };
    };

    extraSettings = lib.mkOption {
      description = "extra settings";
      example = ''
        +net_compresspackets_minsize 64
        +net_compresspackets 1
        +spewlog_enable 0
        +sv_maxrate 127000
      '';
      type = lib.types.listOf lib.types.string;
      default = [ ];
    };

    playlistVars = lib.mkOption {
      description = "playlist variables";
      example = ''
        run_epilogue 0
        featured_mode_amped_tacticals 1
      '';
      type = lib.types.listOf lib.types.string;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      self.overlays.northstar
    ];

    # users = {
    #   groups.${cfg.user} = { };
    #   users.${cfg.user} = {
    #     createHome = lib.mkDefault true;
    #     group = cfg.user;
    #     home = cfg.stateDir;
    #     isSystemUser = lib.mkDefault true;
    #   };
    # };

    systemd.services.satisfactory = {
      description = "Northstar dedicated server";
      requires = [ "network.target" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p ${cfg.stateDir}
        cp -r ${cfg.package-wine-env} ${cfg.stateDir}/wine
      '';

      serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        Type = "exec";
        User = cfg.user;
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe cfg.package-nswine-run.override { nswine-env-path = "${cfg.stateDir}/wine"; })
            ''+ns_server_name="${cfg.settings.name}"''
            ''+ns_server_desc="${cfg.settings.description}"''
            ''+ns_server_password="${
              if cfg.settings.passwordFile == null then
                cfg.settings.password
              else
                builtins.readFile cfg.settings.passwordFile
            }"''
          ]
          ++ cfg.extraSettings
          ++ [
            builtins.concatStringsSep
            ""
            [
              "+setplaylistvaroverrides \""
              (builtins.concatStringsSep " " cfg.playlistVars)
              ''"''
            ]
          ]
        );
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
