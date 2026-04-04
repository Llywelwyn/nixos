{ ... }:
{
  services.caddy.virtualHosts."foundry.ily.rs" = {
    extraConfig = ''
      reverse_proxy localhost:30000
      encode zstd gzip
    '';
  };

  virtualisation.oci-containers.containers.foundry = {
    image = "node:22-slim";
    cmd = [ "node" "main.js" "--dataPath=/data" ];
    workdir = "/app";
    volumes = [
      "/srv/foundry/app:/app:ro"
      "/srv/foundry/data:/data"
    ];
    ports = [ "127.0.0.1:30000:30000" ];
  };
}
