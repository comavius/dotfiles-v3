{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my;
  domain = "headlamp.${cfg.hostname}.home.arpa";
in
{
  networking.hosts."127.0.0.1" = [ domain ];

  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = 80;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:4466";
        proxyWebsockets = true;

        # Headlamp only accepts its loopback address in the Host header.
        recommendedProxySettings = false;
      };
    };
  };

  systemd.services.headlamp = {
    description = "Headlamp Kubernetes web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment.HOME = cfg.homeDirectory;

    serviceConfig = {
      User = cfg.username;
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.headlamp-server)
        "-html-static-dir ${pkgs.headlamp-frontend}"
        "-kubeconfig ${cfg.homeDirectory}/.kube/config"
        "-listen-addr 127.0.0.1"
        "-port 4466"
        "-enable-dynamic-clusters"
      ];
      Restart = "on-failure";
      RestartSec = 5;

      CapabilityBoundingSet = "";
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      UMask = "0077";
    };
  };
}
