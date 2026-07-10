{ ... }:
{
  services.fail2ban = {
    enable = true;
    bantime-increment = {
      enable = true;
      maxtime = "168h";
      overalljails = true;
    };

    jails = {
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
      };
    };
  };

  environment.etc."fail2ban/filter.d/forgejo.conf".text = ''
    [Definition]
    failregex = ^.*Failed authentication attempt for .* from <HOST>
    ignoreregex =
  '';
}
