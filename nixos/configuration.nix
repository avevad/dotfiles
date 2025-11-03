{ config, lib, pkgs, ... }:

let
  ENV = (import ./environment.nix) { pkgs = pkgs; };
in

{
  system.stateVersion = "25.05";

  imports = [
    /etc/nixos/hardware-configuration.nix
    /etc/nixos/hardware-configuration-extras.nix
    ./systemd.nix
    ./wireguard.nix
    ./containers.nix
  ];

  networking = {
    hostName = "NITROGEN";
    domain = "avevad.com";
    fqdn = "nitrogen.avevad.com";
    
    networkmanager.enable = true;
    firewall.enable = false;
  };

  time.timeZone = "Europe/Moscow";

  programs.fish.enable = true;

  users.users.avevad = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      vim
    ];
  };

  environment.systemPackages = with pkgs; [
    htop
    neofetch
    git
    slirp4netns
    python311Full
    python311Packages.pip
  ];

  services = {
    openssh.enable = true;
    openssh.listenAddresses = [ { addr = "10.100.100.10"; port = 22; } ];
    openssh.settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };

    haproxy.enable = true;
    haproxy.config = (builtins.replaceStrings
      [
        "@CERT_FILE@"
        "@CERT_FILE_PUSHY@"
        "@CERT_FILE_TONSBP@"
        "@CERT_FILE_PRO@"
        "@DEPLOY_TOKEN@"
      ]
      [
        "${ pkgs.writeText "haproxy.pem" ENV.HAPROXY_CERT }"
        "${ pkgs.writeText "haproxy.pem" ENV.HAPROXY_CERT_PUSHY }"
        "${ pkgs.writeText "haproxy.pem" ENV.HAPROXY_CERT_TONSBP }"
        "${ pkgs.writeText "haproxy.pem" ENV.HAPROXY_CERT_PRO }"
        ENV.TOKENS.HAPROXY_DEPLOY
      ] 
      (builtins.readFile ./etc/haproxy.cfg)
    );

    dnsmasq.enable = true;
    dnsmasq.resolveLocalQueries = false;
    dnsmasq.settings = {
      server = [ "1.1.1.1" "1.0.0.1" ];
      no-resolv = true;
      no-hosts = true;
      log-queries = true;
      address = [
        # Servers
        "/nitrogen.avedus.pro/10.100.100.10"
        "/helium.avedus.pro/10.100.100.20"
        "/carbon.avedus.pro/10.10.10.10" # Also 10.100.100.30, but this address is preferred
        
        # Important clients
        "/keenetic.avedus.pro/10.10.10.1"
        "/netlink.avedus.pro/10.10.0.1"
      ];
    };
  };
}

