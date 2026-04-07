{ ... }:
{
  services.caddy.virtualHosts."wiki.ily.rs" = {
    extraConfig = ''
      @health path /health-ping
      handle @health {
        reverse_proxy localhost:8070
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

  # Workaround for NixOS/nixpkgs#410857 until backport of #475089 lands
  systemd.services.podman-dokuwiki.serviceConfig.Delegate = true;
}
