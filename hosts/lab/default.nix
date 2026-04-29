{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common
    ./foundry.nix
    ./dokuwiki.nix
    ./forgejo.nix
    ../../modules/site.nix
    ./sites.nix
    ./fail2ban.nix
    ./tinyauth.nix
    ./shlink.nix
    ./guestbook.nix
    ./telegram-alerts.nix
    ../../modules/uptime
  ];

  services.uptime = {
    enable = true;
    interval = "1min";
    services = {
      website = "https://ily.rs";
      forgejo = "https://git.ily.rs";
      foundry = "https://foundry.ily.rs";
      wiki = "https://wiki.ily.rs";
      penfield = "https://penfield.ily.rs";
    };
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
