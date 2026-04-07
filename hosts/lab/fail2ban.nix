{ ... }:
{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "168h";
      overalljails = true;
    };
    ignoreIP = [ "127.0.0.1/8" "::1" ];

    jails = {
      # SSH jail auto-created by NixOS — just tighten the limits
      sshd.settings = {
        maxretry = 3;
        findtime = "15m";
      };

      forgejo.settings = {
        enabled = true;
        port = "http,https,4201";
        filter = "forgejo";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=forgejo.service";
        maxretry = 5;
        findtime = "10m";
      };

      caddy-status.settings = {
        enabled = true;
        port = "http,https";
        filter = "caddy-status";
        backend = "systemd";
        journalmatch = "_SYSTEMD_UNIT=caddy.service";
        maxretry = 10;
        findtime = "10m";
      };
    };
  };

  # Each virtualHost already has a `log` block for access logging.
  # The global `servers { logs }` directive was removed in Caddy 2.11.

  environment.etc."fail2ban/filter.d/forgejo.conf".text = ''
    [Definition]
    failregex = ^.*Failed authentication attempt for .* from <HOST>
    ignoreregex =
  '';

  environment.etc."fail2ban/filter.d/caddy-status.conf".text = ''
    [Definition]
    failregex = ^.*"client_ip":"<HOST>".*"status":\s*(401|403)
    ignoreregex =
  '';
}
