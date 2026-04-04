{ ... }:
{
  services.caddy.virtualHosts."foundry.ily.rs" = {
    extraConfig = ''
      reverse_proxy localhost:30000
      encode zstd gzip
    '';
  };

  virtualisation.oci-containers.containers.foundry = {
    image = "node:22.22.2-slim";
    cmd = [ "node" "main.js" "--dataPath=/data" ];
    workdir = "/app";
    user = "1000:1000";
    volumes = [
      "/srv/foundry/app:/app:ro"
      "/srv/foundry/data:/data"
    ];
    ports = [ "127.0.0.1:30000:30000" ];
  };

  systemd.services.podman-foundry.serviceConfig.User = "lew";
}
