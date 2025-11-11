{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.northstar-dedicated;
in
{
  options.services.northstar-dedicated = {
    enable = lib.mkEnableOption "Northstar Dedicated Server";

    package-nswine-env = lib.mkPackageOption self.packages.${pkgs.system} "nswine-env" { };
    package-nswrap = lib.mkPackageOption self.packages.${pkgs.system} "nswrap" { };
    package-nswine-run = lib.mkPackageOption self.packages.${pkgs.system} "nswine-run" { };
    package-northstar-dedicated =
      lib.mkPackageOption self.packages.${pkgs.system} "northstar-dedicated"
        { };

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
            type = lib.types.str;
            default = "";
          };
          passwordFile = lib.mkOption {
            description = "Specifies the password used by northstar using a file.";
            type = lib.types.pathWith { absolute = true; };
            example = "/run/secrets/my-server-password";
            default = "/run/secrets/not-my-server-password"; # eh nix things ig
          };
          name = lib.mkOption {
            description = "Specifies the name of the server.";
            type = lib.types.str;
            default = "Unnamed Flake Northstar Server";
          };
          description = lib.mkOption {
            description = "Specifies the description of the server.";
            type = lib.types.str;
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
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    playlistVars = lib.mkOption {
      description = "playlist variables";
      example = ''
        run_epilogue 0
        featured_mode_amped_tacticals 1
      '';
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      self.overlays.northstar
    ];

    users = {
      groups.${cfg.user} = { };
      users.${cfg.user} = {
        createHome = lib.mkDefault true;
        group = cfg.user;
        home = cfg.stateDir;
        isSystemUser = lib.mkDefault true;
      };
    };

    systemd.services.northstar-dedicated = {
      description = "Northstar dedicated server";
      requires = [ "network.target" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      path = [
        pkgs.vulkan-tools
        pkgs.vulkan-loader
        pkgs.vulkan-validation-layers
        pkgs.mesa
        pkgs.samba4Full
      ];

      # TODO: should probably delete these files on restart?
      preStart = ''
        # cleanup from previous runs
        # probably not the best tbh
        rm -r ${cfg.stateDir}/wine/bin 2>/dev/null || true
        rm -r ${cfg.stateDir}/bin 2>/dev/null || true
        rm ${cfg.stateDir}/bin/nswrap 2>/dev/null || true
        rm ${cfg.stateDir}/wine/nsrun 2>/dev/null || true

        mkdir -p ${cfg.stateDir}/wine
        mkdir -p ${cfg.stateDir}/bin
        mkdir -p ${cfg.stateDir}/titanfall2

        # chmod 662 ${cfg.stateDir}/titanfall2

        mkdir -p ${cfg.stateDir}/titanfall2/R2Northstar
        mkdir -p ${cfg.stateDir}/titanfall2/R2Northstar/logs
        mkdir -p ${cfg.stateDir}/wine/bin

        mkdir -p ${cfg.stateDir}/.cache
        mkdir -p ${cfg.stateDir}/.cache/fontconfig
        mkdir -p ${cfg.stateDir}/wine/prefix

        cp -r ${cfg.package-nswine-env}/* ${cfg.stateDir}/wine || true
        cp ${cfg.package-nswrap}/bin/nswrap ${cfg.stateDir}/bin/nswrap
        cp ${
          (lib.getExe (cfg.package-nswine-run.override { nswine-env-path = "${cfg.stateDir}/wine"; }))
        } ${cfg.stateDir}/wine/nsrun
        cp -r ${cfg.package-northstar-dedicated}/* ${cfg.stateDir}/titanfall2 || true
      '';

      # # like this?
      # postStop = ''
      #   # # find ${cfg.stateDir} -xtype l -delete
      #   # rm -r ${cfg.stateDir}/titanfall2 2>/dev/null || true
      #   # rm -r ${cfg.stateDir}/wine/bin 2>/dev/null || true
      #   # rm -r ${cfg.stateDir}/bin 2>/dev/null || true
      #   # rm ${cfg.stateDir}/bin/nswrap || true
      #   # rm ${cfg.stateDir}/wine/nsrun || true
      #   # # rm -r ${cfg.stateDir}/wine/bin || true
      # '';

      serviceConfig = {
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        # NoNewPrivileges="yes";
        # ProtectSystem="strict";
        # ProtectHome="read-only";
        # PrivateDevices="yes";
        # RestrictSUIDSGID="yes";
        # RestrictRealtime="yes";
        # RestrictNamespaces="yes";
        # LockPersonality="yes";
        # MemoryDenyWriteExecute="yes";
        # PrivateUsers="yes";
        PrivateTmp = "no";

        # PrivateDevices = "yes";
        # ProtectHostname = "yes";

        # NoNewPrivileges = "yes";
        ReadWritePaths = "/tmp /dev/shm";
        TemporaryFileSystem = "/run:ro";

        Environment = [
          "XDG_RUNTIME_DIR=${lib.escapeShellArg cfg.stateDir}"
          "MESA_LOADER_DRIVER_OVERRIDE=llvmpipe"
          "GALLIUM_DRIVER=llvmpipe"
          "LIBGL_ALWAYS_SOFTWARE=1"
          "DRI_PRIME=0"
          "WINEDEBUG=-all"
          "HOME=/var/lib/northstar"
        ];

        Type = "simple";
        User = cfg.user;
        ExecStart = lib.escapeShellArgs (
          [
            "${cfg.stateDir}/wine/nsrun"
            "${cfg.stateDir}/titanfall2"
            ''+ns_server_name="${cfg.settings.name}"''
            ''+ns_server_desc="${cfg.settings.description}"''
            ''+ns_server_password="${
              if cfg.settings.passwordFile == "/run/secrets/not-my-server-password" then
                cfg.settings.password
              else
                "$(cat ${cfg.settings.passwordFile})"
            }"''
            "-port ${builtins.toString cfg.port}"
          ]
          ++ cfg.extraSettings
          ++ [
            (builtins.concatStringsSep "" [
              "+setplaylistvaroverrides \""
              (builtins.concatStringsSep " " cfg.playlistVars)
              ''"''
            ])
          ]
        );

        # Restart = "always";
        # RestartSec = "10s";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
