{ config, lib, pkgs, ... }:

{
  networking = {
    wireguard.interfaces = {
      # hub.avevad.com
      hub_wg0 = { 
        ips = [ "10.100.100.1/32" ];
        listenPort = 51339;
        privateKeyFile = "/root/wg_f_nitrogen_priv.txt";
        peers = [
          # { # NITROGEN
          #   publicKey = "09mS1qaYV+Q9ct/wpqZje8nwlZs1tHBXMBTm0hxIOms=";
          #   allowedIPs = [ "10.100.100.10/32" "10.100.0.0/24" ];
          # }
          { # HELIUM
            publicKey = "frYUUl/wWzMUeiIzjjzZeAkWCg7tie4KwtCK3yqCum8=";
            allowedIPs = [ "10.100.100.20/32" ];
          }
          { # CARBON
            publicKey = "W3iaqQovfM23eAYqTWraxI7rRYDppqKrdeT+d4IN3zI=";
            allowedIPs = [ "10.100.100.30/32" "10.10.0.0/16" ];
          }
        ];
      };

      # gateway.avevad.com
      gateway_wg0 = {
        ips = [ "10.100.100.10/32" "10.100.0.1/24" ];
        listenPort = 51337;
        privateKeyFile = "/root/wg_nitrogen_priv.txt";
        peers = [
          # {
          #   publicKey = "jD9IEOpc2ZcoOTZ2bUHexmns1/OBKPl6PeApovWcJSs=";
          #   allowedIPs = [ "10.0.0.0/8" ];
          #   endpoint = "hub.avevad.com:51339";
          # }
        ] ++ ( import ./wireguard/wg0.nix );
        postSetup = ''
          ip route add default dev gateway_wg1 table 42
          ip route add 10.100.0.0/24 dev gateway_wg0 table 42
          ip route add 10.0.0.0/8 dev hub_wg0 table 42
          ip rule add iif gateway_wg0 table 42
        '';
        preShutdown = ''
          ip rule delete iif gateway_wg0
          ip route flush table 42
        '';
      };
      gateway_wg1 = { # Egress transit
        ips = [ "10.100.254.1/32" ];
        listenPort = 51340;
        privateKeyFile = "/root/wg_f_nitrogen_priv.txt";
        allowedIPsAsRoutes = false;
        peers = [
          {
            publicKey = "frYUUl/wWzMUeiIzjjzZeAkWCg7tie4KwtCK3yqCum8=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "egress.avevad.com:51340";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}

