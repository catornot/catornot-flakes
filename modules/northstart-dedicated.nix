{ self, inputs }:
{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  cfg = config.services.northstar-dedicated;
  lib = args.lib // (self.libExport pkgs);
in
let
  bpOrtModule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = ''
          enables bp-ort and adds it to your packages
        '';
        # package = lib.mkPackageOption inputs.bp-ort.packages.${pkgs.system} "nswrap" { };
      };
    };
  };
  profileModule = lib.types.submodule {
    options = {
      package-names = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        description = ''
          the names of packages on thunderstore in this format <team>-<package>-<version> and a hash
        '';
        default = [ ];
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        description = ''
          some packages
        '';
        default = [ ];
      };
      bp-ort = lib.mkOption {
        type = bpOrtModule;
        description = ''
          the a special place for configuring and setting up bp-ort
        '';
        default = { };
      };
    };
  };
in
{
  options.services.northstar-dedicated = {
    enable = lib.mkEnableOption "Northstar Dedicated Server";

    package-check-hash = lib.mkPackageOption self.packages.${pkgs.system} "check-hash" { };
    package-nswine-env = lib.mkPackageOption self.packages.${pkgs.system} "nswine-env" { };
    package-nswine = lib.mkPackageOption self.packages.${pkgs.system} "nswine" { };
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

    profile = lib.mkOption {
      type = profileModule;
      description = "Northstar Profile";
      default = { };
      example = lib.literalExpression ''
        {
          package-names = [
            { name = "cat_or_not-AmpedMobilepoints-0.0.4"; sha256 = lib.fakeHash; }
            { name = "IMC-Spyglass-2.2.1"; sha256 = lib.fakeHash; }
          ];
          bp-ort.enable = true;
        }
      '';
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
        cfg.package-nswine
      ];

      preStart =
        let
          wrapInFolder = name: ''
            if [ -z "$(ls -A $out)" ]; then
              echo "Empty"
            else
              mv $out/* $TMP
              mkdir -p $out/${name}
              mv $TMP/* $out/${name}
            fi
          '';
          unwrapDir = name: ''
            mv $out/${name}/* $TMP
            rm -r $out
            mkdir -p $out
            mv $TMP/* $out
          '';
          bp-ort-mod = inputs.bp-ort.packages.${pkgs.system}.mod;
          navmeshes = inputs.bp-ort.packages.${pkgs.system}.navmeshes;

          northstar-packages =
            (builtins.map lib.nameToPackage cfg.profile.package-names) ++ cfg.profile.packages;
          northstar-mods = lib.optional cfg.profile.bp-ort.enable (
            pkgs.symlinkJoin {
              name = "catornot-bp_ort-${bp-ort-mod.version}";
              paths = [ bp-ort-mod ];
              postBuild = unwrapDir "mods";
            }
          );
          northstar-plugins = lib.optional cfg.profile.bp-ort.enable (
            pkgs.symlinkJoin {
              name = "catornot-bp_ort-${bp-ort-mod.version}";
              paths = [
                inputs.bp-ort.packages.${pkgs.system}.bp-ort
                inputs.bp-ort.packages.${pkgs.system}.octbots
                inputs.bp-ort.packages.${pkgs.system}.ranim
              ];
              postBuild = unwrapDir "bin";
            }
          );
          northstar-extras = (
            lib.optional cfg.profile.bp-ort.enable (
              pkgs.symlinkJoin {
                name = "octnavs";
                paths = [ navmeshes ];
                postBuild = wrapInFolder "octnavs";
              }
            )
          );
          titanfall2-install = cfg.package-northstar-dedicated.override {
            inherit
              northstar-packages
              northstar-mods
              northstar-extras
              northstar-plugins
              ;
          };
        in
        ''
          mkdir -p ${cfg.stateDir}
          chown ${cfg.user}:${config.users.users.${cfg.user}.group} ${cfg.stateDir}

          mkdir -p ${cfg.stateDir}/.cache
          mkdir -p ${cfg.stateDir}/.cache/fontconfig
          mkdir -p ${cfg.stateDir}/wine/prefix

          # this also copies over the titanfall2 install
          ${lib.getExe (
            cfg.package-check-hash.override {
              original = titanfall2-install;
              installed = "${cfg.stateDir}/titanfall2"; # TODO: this will break if we support multiple profiles
              hashFileName = "r2NorthstarHash";
            }
          )}

          chown -R ${cfg.user}:${config.users.users.${cfg.user}.group} ${cfg.stateDir}
          chmod -R a+rw ${cfg.stateDir}

          export WINEARCH=win64 WINEDLLOVERRIDES=\"mscoree,mshtml,winemenubuilder.exe=\"
          mkdir -p "$WINEPREFIX"

        ''
        + "
          ${lib.getExe' cfg.package-nswine "wine"} wineboot --init
          ${lib.getExe' cfg.package-nswine "wine"} reg add 'HKCU\\Software\\Wine' /v 'Version' /t REG_SZ /d 'win10' /f
          ${lib.getExe' cfg.package-nswine "wine"} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Audio' /t REG_SZ /d '' /f
          ${lib.getExe' cfg.package-nswine "wine"} reg add 'HKCU\\Software\\Wine\\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
          ${lib.getExe' cfg.package-nswine "wine"} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Graphics' /t REG_SZ /d 'null' /f
          ${lib.getExe' cfg.package-nswine "wine"} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mscoree' /t REG_SZ /d '' /f
          ${lib.getExe' cfg.package-nswine "wine"} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mshtml' /t REG_SZ /d '' /f
          ${lib.getExe' cfg.package-nswine "wine"} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'winemenubuilder' /t REG_SZ /d '' /f
          ${lib.getExe' cfg.package-nswine "wine"} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'd3d11' /t REG_SZ /d 'native' /f
          ${lib.getExe' cfg.package-nswine "wine"} wineboot --shutdown --force
          ${lib.getExe' cfg.package-nswine "wine"} wineboot --kill --force
       ";

      serviceConfig = {
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        # NoNewPrivileges="yes";
        # ProtectSystem="strict";
        # ProtectHome="read-only";
        # RestrictSUIDSGID="yes";
        # RestrictRealtime="yes";
        # RestrictNamespaces="yes";
        # LockPersonality="yes";
        # MemoryDenyWriteExecute="yes";
        # PrivateUsers="yes";
        PrivateTmp = "yes";

        PrivateDevices = "yes";
        ProtectHostname = "yes";

        # NoNewPrivileges = "yes";
        # ReadWritePaths = "/tmp";

        Environment = [
          "NSWRAP_DEBUG=0"
          "NSWRAP_EXTWINE=1"
          "WINEPREFIX=${cfg.stateDir}/wine/wine"
        ];

        Type = "simple";
        User = cfg.user;
        ExecStart = lib.escapeShellArgs (
          [
            "${lib.getExe' pkgs.coreutils-full "env"}"
            "-C"
            "${cfg.stateDir}/titanfall2"
            "${lib.getExe cfg.package-nswrap}"
            "-dedicated"
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

        ExecStopPost = "${lib.getExe' pkgs.coreutils "rm"} -rf ${cfg.stateDir}/wine";

        Restart = "always";
        RestartSec = "10s";
        WorkingDirectory = cfg.stateDir;
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
