{ pkgs, ... }:
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
    ./fail2ban.nix
    ./tinyauth.nix
    ./shlink.nix
    ./guestbook.nix
    ./rustypaste.nix
    ./telegram-alerts.nix
    ../../modules/uptime
  ];

  services.uptime = {
    enable = true;
    displayDays = 90;
    intro = ''
      This page is written in Bash. It tracks 90 days of historical uptime
      data for various services. This page regenerates every 1 minute.
    '';
    categories = [
      {
        description = "My services";
        intervalSeconds = 60;
        services = [
          { name = "website";   url = "https://ily.rs"; }
          { name = "guestbook"; url = "https://ily.rs/guestbook"; }
          { name = "file";      url = "https://file.ily.rs/health-ping"; }
          { name = "git";       url = "https://git.ily.rs"; }
          { name = "records";   url = "https://c.ily.rs"; }
          { name = "penfield";  url = "https://penfield.ily.rs"; }
          { name = "wiki";      url = "https://wiki.ily.rs/health-ping"; }
          { name = "foundry";   url = "https://foundry.ily.rs"; }
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
  services.caddy.email = "lew@ily.rs";

  system.stateVersion = "23.11";
}
