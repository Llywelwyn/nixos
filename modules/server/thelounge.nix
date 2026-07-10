{
  flake.modules.nixos.server = {
    services = {
      uptime-page.probes.irc = { url = "https://irc.ily.rs"; order = 120; };
      telegram-alerts.units = [ "thelounge" ];

      caddy.virtualHosts."irc.ily.rs" = {
        extraConfig = ''
          import favicons
          reverse_proxy localhost:9000
          encode zstd gzip
        '';
      };

      thelounge = {
        enable = true;
        extraConfig = {
          host = "127.0.0.1";
          reverseProxy = true;
          defaults = {
            name = "Libera.Chat";
            host = "irc.libera.chat";
            port = 6697;
            tls = true;
            nick = "llywelwyn";
            join = "##roguelikedev";
          };
        };
      };
    };
  };
}
