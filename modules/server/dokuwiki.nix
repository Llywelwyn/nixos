{
  flake.modules.nixos.server = { pkgs, ... }:
  let
    goatcounterJs = pkgs.writeText "dokuwiki-userscript.js" ''
      window.goatcounter = { path: function (p) { return location.host + p } };
      (function () {
        var s = document.createElement('script');
        s.async = true;
        s.dataset.goatcounter = 'https://stats.ily.rs/count';
        s.src = 'https://stats.ily.rs/count.js';
        document.head.appendChild(s);
      })();
    '';
    initOpenssh = pkgs.writeTextFile {
      name = "30-openssh";
      executable = true;
      text = ''
        #!/bin/sh
        set -e
        command -v ssh >/dev/null 2>&1 || apk add --no-cache openssh-client
        if [ ! -f /config/.ssh/known_hosts ] || ! grep -q "^github.com " /config/.ssh/known_hosts; then
          mkdir -p /config/.ssh
          ssh-keyscan -t ed25519,rsa github.com >> /config/.ssh/known_hosts 2>/dev/null
          chmod 600 /config/.ssh/known_hosts
        fi
      '';
    };
  in
  {
    services.uptime-page.probes.wiki = { url = "https://wiki.ily.rs/health-ping"; order = 70; };

    services.caddy.virtualHosts."wiki.ily.rs" = {
      extraConfig = ''
        import favicons

        @health path /health-ping
        handle @health {
          respond 200
        }

        handle {
          import tinyauth
          reverse_proxy localhost:8070
          encode zstd gzip
        }
      '';
    };

    virtualisation.oci-containers.containers.dokuwiki = {
      image = "lscr.io/linuxserver/dokuwiki:2025-05-14b-ls299";
      podman.user = "podman";
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "Europe/London";
      };
      volumes = [
        "/srv/dokuwiki/config:/config"
        "/srv/dokuwiki/cont-init.d:/custom-cont-init.d:ro"
      ];
      ports = [ "127.0.0.1:8070:80" ];
    };

    systemd.tmpfiles.settings."10-dokuwiki" = {
      "/srv/dokuwiki/cont-init.d/30-openssh"."C+" = {
        argument = "${initOpenssh}";
        user = "100999";
        group = "100999";
        mode = "0755";
      };
      "/srv/dokuwiki/config/dokuwiki/conf/userscript.js"."C+" = {
        argument = "${goatcounterJs}";
        user = "100999";
        group = "100999";
        mode = "0644";
      };
    };
  };
}
