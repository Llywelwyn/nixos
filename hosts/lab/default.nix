{ pkgs, ... }:
let
  uptimeDisplayDays = 90;
  uptimeFastInterval = 60;
in
{
  imports = [
    ./hardware-configuration.nix
    ../common
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
    ../../modules/uptime
  ];

  services.uptime-page = {
    enable = true;
    displayDays = uptimeDisplayDays;
    intro = ''
      This page is written in Bash. It tracks ${toString uptimeDisplayDays} days of historical uptime
      data for various services. This page regenerates every ${toString uptimeFastInterval} seconds.
      Probes run from the same machine that hosts these services, so a
      gap (.) can also mean the machine itself was down.
    '';
    categories = [
      {
        description = "My services";
        intervalSeconds = uptimeFastInterval;
        services = [
          { name = "website";   url = "https://ily.rs"; }
          { name = "guestbook"; url = "https://ily.rs/guestbook"; }
          { name = "file";      url = "https://file.ily.rs/health-ping"; }
          { name = "git";       url = "https://git.ily.rs"; }
          { name = "records";   url = "https://c.ily.rs"; }
          { name = "penfield";  url = "https://penfield.ily.rs"; }
          { name = "wiki";      url = "https://wiki.ily.rs/health-ping"; }
          { name = "foundry";   url = "https://foundry.ily.rs"; }
          { name = "auth";      url = "https://auth.ily.rs"; }
          { name = "x";         url = "https://x.ily.rs"; }
          { name = "stats";     url = "https://stats.ily.rs"; }
        ];
      }
      {
        description = "Other services";
        intervalSeconds = 300;
        hideUrls = true;
        services = [
          { name = "co-surf";   url = "https://co-surf.com"; }
          { name = "frontline"; url = "https://essexfrontline.org.uk"; }
        ];
      }
    ];
  };

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

  users.users.podman = {
    isSystemUser = true;
    group = "podman";
    home = "/var/lib/podman";
    createHome = true;
    uid = 900;
    linger = true;
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    subGidRanges = [{ startGid = 100000; count = 65536; }];
  };
  users.groups.podman = {};

  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";

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

  system.stateVersion = "23.11";
}
