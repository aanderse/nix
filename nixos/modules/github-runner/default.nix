{ modulesPath, config, pkgs, lib, ... }: with lib;
let
  cfg = config.services.github-runner;

  # systemd hardening used in upstream module
  ignoreAttrs = [
    "AmbientCapabilities"
    "CapabilitiesBoundingSet"
    "DeviceAllow"
    "DynamicUser"
    "InaccessiblePaths"
    "LockPersonality"
    "MemoryDenyWriteExecute"
    "NoNewPrivileges"
    "PrivateDevices"
    "PrivateMounts"
    "PrivateNetwork"
    "PrivateUsers"
    "ProcSubset"
    "ProtectClock"
    "ProtectControlGroups"
    "ProtectHome"
    "ProtectHostname"
    "ProtectKernelLogs"
    "ProtectKernelModules"
    "ProtectKernelTunables"
    "ProtectProc"
    "ProtectSystem"
    "RemoveIPC"
    "RestrictNamespaces"
    "RestrictRealtime"
    "RestrictSUIDSGID"
    "SystemCallFilter"
  ];
in
{
  disabledModules = [
    "services/continuous-integration/github-runner.nix"
    "services/continuous-integration/github-runners.nix"
  ];

  # interface
  options.services.github-runner = import "${modulesPath}/services/continuous-integration/github-runner/options.nix" ({
    inherit config pkgs lib;
    # Users don't need to specify options.services.github-runner.name; it will default
    # to the hostname.
    includeNameDefault = true;
  }) // {
    user = mkOption {
      type = types.str;
      default = "github-runner";
      description = mdDoc ''
        User account under which github-runner runs.

        ::: {.note}
        If left as the default value this user will automatically be created
        on system activation, otherwise the sysadmin is responsible for
        ensuring the user exists before the maddy service starts.
        :::
      '';
    };

    group = mkOption {
      type = types.str;
      default = "github-runner";
      description = mdDoc ''
        Group account under which github-runner runs.

        ::: {.note}
        If left as the default value this group will automatically be created
        on system activation, otherwise the sysadmin is responsible for
        ensuring the group exists before the maddy service starts.
        :::
      '';
    };
  };

  # implementation
  config = mkIf cfg.enable {

    systemd.services.github-runner =
      let
        service = import "${modulesPath}/services/continuous-integration/github-runner/service.nix" {
          inherit config pkgs lib;

          svcName = "github-runner";
        };
      in
        service // { serviceConfig = (builtins.removeAttrs service.serviceConfig ignoreAttrs) // { User = cfg.user; Group = cfg.group; }; };

    users.users = optionalAttrs (cfg.user == "github-runner") {
      github-runner = {
        isSystemUser = true;
        group = config.users.groups.github-runner.name;
        home = "/var/lib/github-runner";
        useDefaultShell = true;
      };
    };

    users.groups = optionalAttrs (cfg.group == "github-runner") {
      github-runner = { };
    };

  };
}
