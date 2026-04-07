{ ... }:
{
  services.caddy.virtualHosts."status.ily.rs" = {
    extraConfig = ''
      reverse_proxy localhost:3001
      encode zstd gzip
    '';
  };

  services.caddy.virtualHosts."status.wynne.rs" = {
    extraConfig = ''
      redir https://status.ily.rs{uri} permanent
    '';
  };

  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "louislam/uptime-kuma:2";
    podman.user = "podman";
    volumes = [
      "/srv/uptime-kuma/data:/app/data"
    ];
    ports = [ "127.0.0.1:3001:3001" ];
  };

  # Workaround for NixOS/nixpkgs#410857 until backport of #475089 lands
  systemd.services.podman-uptime-kuma.serviceConfig.Delegate = true;
}
