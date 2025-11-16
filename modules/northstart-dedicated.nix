{ self, inputs }:
{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  toType =
    type: value:
    {
      "int" = lib.toInt;
      "str" = str: "\"${builtins.toString str}\"";
      "port" = lib.toInt;
      "float" = (
        v:
        let
          strVal = builtins.fromJSON v;
          forceFloat = i: if lib.isFloat i then i else i + 0.5 - 0.5;
        in
        assert (builtins.isInt v || lib.isString v);
        if lib.isString v then
          forceFloat strVal
        else if lib.isInt v then
          forceFloat v
        else
          v
      ); # eh
    }
    .${type}
      value;

  cfg = config.services.northstar-dedicated;
  lib = args.lib // (self.libExport pkgs);
  cfg_settingsJson = builtins.fromJSON (lib.readFile ./cfg_settings.json);
  cfg_settings_list = lib.mapAttrsToList (name: _: name) cfg_settingsJson;
  cfg_settings = lib.mapAttrs (
    name: info:
    lib.mkOption {
      type = lib.types.${info.type or "str"};
      description = info.description or "";
      default = toType (info.type or "str") info.value or '''""'';
    }
  ) cfg_settingsJson;
in
let
  bpOrtModule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = ''
          enables bp-ort and adds it to your packages
        '';
        default = false;
      };
    };
  };
  rconModule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = ''
          enables r2rcon-rs and adds it to your packages
        '';
        default = false;
      };
      sshKeys = lib.mkOption {
        type = lib.types.listOf lib.types.singleLineStr;
        description = ''
          adds public ssh keys to the ${cfg.user} user
        '';
        default = [ ];
      };
      password = lib.mkOption {
        type = lib.types.str;
        description = ''
          password for the rcon connection by default it's psk
        '';
        default = "psk";
      };
    };
  };
  profileModule = lib.types.submodule {
    options = (
      {
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
        rcon = lib.mkOption {
          type = rconModule;
          description = ''
            the a special place for configuring and setting up rcon
          '';
          default = {
            enable = false;
          };
        };

        # settings
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
        port = lib.mkOption {
          type = lib.types.port;
          default = 37015;
          description = ''
            Override the Game Port the server uses.
          '';
        };

        extraSettings = lib.mkOption {
          description = "extra settings";
          example = ''
            ns_auth_allow_insecure 1
            ns_private_match_last_mode tdm
          '';
          type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.int);
          default = { };
        };

        # playlist vars
        playlistVars = lib.mkOption {
          description = "playlist variables";
          example = ''
            run_epilogue 0
            featured_mode_amped_tacticals 1
          '';
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      }
      // cfg_settings
    );
  };
in
{
  options.services.northstar-dedicated = {
    enable = lib.mkEnableOption "Northstar Dedicated Server";

    package-rustcon = lib.mkPackageOption self.packages.${pkgs.system} "rustcon" { };
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

    openFirewall = lib.mkEnableOption "" // {
      description = "Whether to open the ports in the firewall.";
    };

    extraArgs = lib.mkOption {
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
      description = "Northstar Profile; settings, mods, etc";
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
        shell =
          (pkgs.writeShellApplication {
            name = "rustcon-psk";
            text = "RUSTCON_PASS=${cfg.profile.rcon.password} ${lib.getExe cfg.package-rustcon}";
          })
          // {
            shellPath = "bin/rustcon-psk";
          };
        useDefaultShell = false;
        openssh.authorizedKeys.keys = if cfg.profile.rcon.enable then cfg.profile.rcon.sshKeys else [ ];
        ignoreShellProgramCheck = true;
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
          northstar-plugins =
            (lib.optional cfg.profile.bp-ort.enable (
              pkgs.symlinkJoin {
                name = "catornot-bp_ort-${bp-ort-mod.version}";
                paths = [
                  inputs.bp-ort.packages.${pkgs.system}.bp-ort
                  inputs.bp-ort.packages.${pkgs.system}.octbots
                  inputs.bp-ort.packages.${pkgs.system}.ranim
                ];
                postBuild = unwrapDir "bin";
              }
            ))
            ++ (lib.optional cfg.profile.rcon.enable (
              pkgs.symlinkJoin {
                name = "catornot-r2rcon-rs";
                paths = [
                  inputs.r2rcon-rs.packages.${pkgs.system}.default
                ];
                postBuild = unwrapDir "bin";
              }
            ));
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
            server-settings =
              (builtins.listToAttrs (
                builtins.map (value: {
                  name = value;
                  value = "${builtins.toString cfg.profile.${value}}";
                }) cfg_settings_list
              ))
              // cfg.profile.extraSettings;
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
        RestrictSUIDSGID = "yes";
        LockPersonality = "yes";
        PrivateUsers = "yes";
        PrivateTmp = "yes";

        PrivateDevices = "yes";
        ProtectHostname = "yes";

        NoNewPrivileges = "yes";

        ProtectSystem = "full";
        ReadWritePaths = "${cfg.stateDir}";
        NoExecPaths = "/";
        ExecPaths = "/nix ${cfg.stateDir}";

        Environment = [
          "NSWRAP_DEBUG=0"
          "NSWRAP_EXTWINE=1"
          "WINEPREFIX=${cfg.stateDir}/wine/wine"
        ];

        Type = "simple";
        User = cfg.user;
        ExecStart = builtins.concatStringsSep " " (
          [
            "${lib.getExe' pkgs.coreutils-full "env"}"
            "-C"
            "${cfg.stateDir}/titanfall2"
            "${lib.getExe cfg.package-nswrap}"
            "-dedicated"
            ''+ns_server_password="${
              if cfg.profile.passwordFile == "/run/secrets/not-my-server-password" then
                cfg.profile.password
              else
                "$(cat ${cfg.settings.profile.passwordFile})"
            }"''
            "-port ${builtins.toString cfg.profile.port}"
          ]
          ++ cfg.extraArgs
          ++ [
            (builtins.concatStringsSep "" [
              "+setplaylistvaroverrides \""
              (builtins.concatStringsSep " " cfg.profile.playlistVars)
              ''"''
            ])
          ]
          ++ (
            if cfg.profile.rcon.enable then
              [
                "-rcon_ip_port 127.0.0.1:27015"
                "-rcon_password ${cfg.profile.rcon.password}"
              ]
            else
              [ ]
          )
        );

        ExecStopPost = "${lib.getExe' pkgs.coreutils "rm"} -rf ${cfg.stateDir}/wine";

        KillMode = "mixed";
        Restart = "always";
        RestartSec = "10s";
        WorkingDirectory = cfg.stateDir;
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [ cfg.profile.port ];
    };
  };
}
