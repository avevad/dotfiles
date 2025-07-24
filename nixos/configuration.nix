{ config, lib, pkgs, ... }:

let
  ENV = (import ./environment.nix) { pkgs = pkgs; };
in

{
  system.stateVersion = "23.11";

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
    openssh.listenAddresses = [ { addr = "10.100.0.1"; port = 22; } ];
    openssh.settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };

    haproxy.enable = true;
    haproxy.config = (builtins.replaceStrings
      [
        "@CERT_FILE@"
        "@CERT_FILE_PUSHY@"
        "@DEPLOY_TOKEN@"
      ]
      [
        "${ pkgs.writeText "haproxy.pem" ENV.HAPROXY_CERT }"
        "${ pkgs.writeText "haproxy.pem" ENV.HAPROXY_CERT_PUSHY }"
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
      address = [
        "/nitrogen.avevad.com/10.100.0.1"
        "/helium.avevad.com/10.200.0.1"
        "/oxygen.avevad.com/10.100.0.5"
      ];
      log-queries = true;
    };
  };
}

