{ self }:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.northstar-dedicated;
in
{
  options.services.northstar-dedicated = {
    enable = lib.mkEnableOption "Northstar Dedicated Server";

    package-nswine-env = lib.mkPackageOption pkgs "nswine-env" { };
    package-nswrap = lib.mkPackageOption pkgs "nswrap" { };
    package-nswine-run = lib.mkPackageOption pkgs "nswine-run" { };
    package-northstar-dedicated = lib.mkPackageOption pkgs "northstar-dedicated" { };

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

      # TODO: should probably delete these files on restart?
      preStart = ''
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

        cp -u -r ${cfg.package-nswine-env}/* ${cfg.stateDir}/wine
        cp -p -u -r ${cfg.package-nswrap}/bin/nswrap ${cfg.stateDir}/bin/nswrap
        cp -p -u -r ${
          (lib.getExe (cfg.package-nswine-run.override { nswine-env-path = "${cfg.stateDir}/wine"; }))
        } ${cfg.stateDir}/wine/nsrun
        cp -u -r ${cfg.package-northstar-dedicated}/* ${cfg.stateDir}/titanfall2


      '';

      # like this?
      postStop = ''
        # find ${cfg.stateDir} -xtype l -delete
        # rm -r ${cfg.stateDir}/titanfall2
        # rm -r ${cfg.stateDir}/wine
        # rm -r ${cfg.stateDir}/bin
        rm ${cfg.stateDir}/bin/nswrap
        rm ${cfg.stateDir}/wine/nsrun
        rm -r ${cfg.stateDir}/wine/bin
      '';

      path = with pkgs; [
        libGL
        stdenv.cc
        zstd
        libxkbcommon
        vulkan-loader
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
        xorg.libXrandr
        alsa-lib
        wayland
        glfw-wayland
        udev
        pkg-config
      ];

      serviceConfig = {
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;

        PrivateDevices = "yes";
        ProtectHostname = "yes";
        NoNewPrivileges = "yes";

        Environment = [
          "LIBGL_ALWAYS_SOFTWARE=1"
          "GALLIUM_DRIVER=llvmpipe"
        ];

        Type = "exec";
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
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
