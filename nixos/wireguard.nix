{ config, lib, pkgs, ... }:

{
  networking = {
    nat = {
      enable = true;
      externalInterface = "eth0";
      internalInterfaces = [ "wg0" "wg01" ];
    };

    wireguard.interfaces = {
      wg1 = { # HELIUM BRIDGE
        ips = [ "10.200.0.2/24" ];
        listenPort = 51488;
        allowedIPsAsRoutes = false;

        postSetup = ''
          ip route add default via 10.200.0.1 table 228
          ip route add 10.100.0.0/24 dev wg0 table 228
          ip rule add iif wg0 table 228
          ip rule add iif wg0 to 172.17.0.1/16 table main

          ip route add default via 10.200.0.1 table 229
          ip route add 10.101.0.0/24 dev wg01 table 229
          ip rule add iif wg01 table 229
        '';
        postShutdown = ''
          ip rule delete iif wg0
          ip rule delete iif wg0 to 172.17.0.1/16
          ip route flush table 228

          ip rule delete iif wg01
          ip route flush table 229
        '';

        privateKeyFile = "/root/wg_nitrogen_priv.txt";
        peers = [
          { # HELIUM
            publicKey = "frYUUl/wWzMUeiIzjjzZeAkWCg7tie4KwtCK3yqCum8=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "helium.avevad.com:51488";
            persistentKeepalive = 25;
         }
        ];
      };

      wg01 = { # PUBLIC VPN
        ips = [ "10.101.0.1/24" ];
        listenPort = 51338;

        privateKeyFile = "/root/wg_f_nitrogen_priv.txt";
        peers = import ./wireguard/wg01.nix;
      };

      wg0 = { # INTERNAL VPN
        ips = [ "10.100.0.1/24" ];
        listenPort = 51337;

        privateKeyFile = "/root/wg_nitrogen_priv.txt";
        peers = import ./wireguard/wg0.nix;
      };
    };
  };
}

