{
  flake.modules.nixos.server = { config, ... }:
  {
    sops.secrets.linkding-env = {
      sopsFile = ../../secrets/linkding.yaml;
      key = "env";
      owner = "podman";
    };

    services = {
      uptime-page.probes.bookmarks = { url = "https://bookmarks.ily.rs"; order = 106; };

      caddy.virtualHosts."bookmarks.ily.rs" = {
        extraConfig = ''
          import favicons
          reverse_proxy localhost:8082
          encode zstd gzip
        '';
      };
    };

    virtualisation.oci-containers.containers.linkding = {
      image = "sissbruecker/linkding:1.45.0";
      podman.user = "podman";
      volumes = [ "/srv/linkding/data:/etc/linkding/data" ];
      ports = [ "127.0.0.1:8082:9090" ];
      environment = {
        LD_CSRF_TRUSTED_ORIGINS = "https://bookmarks.ily.rs";
      };
      environmentFiles = [ config.sops.secrets.linkding-env.path ];
    };

    systemd.tmpfiles.rules = [
      "d /srv/linkding/data 0750 podman podman -"
    ];
  };
}
