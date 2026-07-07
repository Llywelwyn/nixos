{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common
    ./podman.nix
    ./uptime.nix
    ./foundry.nix
    ./dokuwiki.nix
    ./forgejo.nix
    ../../modules/favicons.nix
    ../../modules/site.nix
    ./sites.nix
    ./cdn.nix
    ./fail2ban.nix
    ./tinyauth.nix
    ./guestbook.nix
    ./rustypaste.nix
    ./telegram-alerts.nix
    ./goatcounter.nix
    ./thelounge.nix
    ./ergo.nix
    ./discord-irc.nix
    ../../modules/uptime
  ];

  networking.hostName = "lab";

  services.openssh = {
    enable = true;
    ports = [ 4200 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 4200 ];

  security.sudo.wheelNeedsPassword = false;

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  environment.systemPackages = with pkgs; [
    sqlite
  ];

  boot.tmp.cleanOnBoot = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  services.caddy.enable = true;
  services.caddy.email = "l@ily.rs";
  services.telegram-alerts.units = [ "caddy" ];

  system.stateVersion = "23.11";
}
