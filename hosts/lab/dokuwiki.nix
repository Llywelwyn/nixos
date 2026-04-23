{ pkgs, ... }:
let
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
  services.caddy.virtualHosts."wiki.ily.rs" = {
    extraConfig = ''
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

  systemd.tmpfiles.settings."10-dokuwiki"."/srv/dokuwiki/cont-init.d/30-openssh"."C+" = {
    argument = "${initOpenssh}";
    user = "100999";
    group = "100999";
    mode = "0755";
  };

  # Workaround for NixOS/nixpkgs#410857 until backport of #475089 lands
  systemd.services.podman-dokuwiki.serviceConfig.Delegate = true;
}
