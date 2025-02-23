{ config, lib, pkgs, ... }:

let
  ENV = (import ./environment.nix) { pkgs = pkgs; };
in

{
  systemd.sockets.deploy = {
    enable = true;
    description = "Deployment Requests Socket";
    socketConfig = {
      ListenStream = "127.0.0.1:1488";
      Accept = true;
    };
    wantedBy = [ "sockets.target" ];
  };

  systemd.services."deploy@" = {
    description = "Deployment Service";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${ pkgs.bash }/bin/bash ${ ./scripts/deploy.sh } %i";
      WorkingDirectory = "/etc/nixos/deployment/";
      StandardInput = "socket";
      StandardOutput = "socket";
      StandardError = "journal";
    };
    wantedBy = lib.mkForce [ ];
  };

  systemd.services.pushy-error-logs = {
    enable = true;
    description = "Export Error Journal to Pushy";
    after = [ "network.target" "docker-pushy-tgbot.service" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${ pkgs.bash }/bin/bash -c '${ pkgs.systemd }/bin/journalctl -perr -f -n0 | /root/.local/bin/pushy send -c -m code'";
      StandardOutput = "null";
      StandardError = "journal";
      Environment = "PUSHY_API_KEY=${ ENV.TOKENS.ERR_LOGS_API_KEY }";
      Restart = "on-failure";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.pushy-error-logs-pushy = {
    enable = true;
    description = "Export Error Journal to Pushy (Pushy Production)";
    after = [ "network.target" "docker-pushy-tgbot.service" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${ pkgs.bash }/bin/bash -c '${ pkgs.systemd }/bin/journalctl -perr -f -n0 CONTAINER_NAME=pushy-tgbot | /root/.local/bin/pushy send -c -m code'";
      StandardOutput = "null";
      StandardError = "journal";
      Environment = "PUSHY_API_KEY=${ ENV.TOKENS.ERR_LOGS_PUSHY_API_KEY }";
      Restart = "on-failure";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.docker-pushy-tgbot = {
    after = [ "docker-pushy-postgres.service" ];
  };

  systemd.services.docker-pushy-test-tgbot = {
    after = [ "docker-pushy-postgres.service" ];
  };
}

