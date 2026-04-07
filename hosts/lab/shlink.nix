{ config, pkgs, ... }:
{
  sops.secrets.shlink-api-key = {
    sopsFile = ../../secrets/shlink.yaml;
  };

  sops.templates.shlink-env = {
    content = ''
    INITIAL_API_KEY=${config.sops.placeholder.shlink-api-key}
    '';
    owner = "podman";
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    ensureDatabases = [ "shlink" ];
    ensureUsers = [{
      name = "shlink";
      ensureDBOwnership = true;
    }];
    authentication = pkgs.lib.mkOverride 10 ''
      local all       all     trust
      host  sameuser  all     127.0.0.1/32 trust
      host  sameuser  all     ::1/128      trust
      host  sameuser  all     10.0.0.0/8   trust
    '';
  };

  services.caddy.virtualHosts."ily.rs" = {
    extraConfig = ''
      reverse_proxy localhost:8080
      encode zstd gzip
    '';
  };

  services.caddy.virtualHosts."links.ily.rs" = {
    extraConfig = ''
      @health path /health-ping
      handle @health {
        respond 200
      }

      handle {
        import tinyauth
        reverse_proxy localhost:8081
        encode zstd gzip
      }
    '';
  };

  virtualisation.oci-containers.containers.shlink = {
    image = "shlinkio/shlink:5.0.1";
    podman.user = "podman";
    ports = [ "127.0.0.1:8080:8080" ];
    environment = {
      DEFAULT_DOMAIN = "ily.rs";
      IS_HTTPS_ENABLED = "true";
      DB_DRIVER = "postgres";
      DB_HOST = "host.containers.internal";
      DB_NAME = "shlink";
      DB_USER = "shlink";
      PORT = "8080";
      SHELL_VERBOSITY = "3";
    };
    environmentFiles = [ config.sops.templates.shlink-env.path ];
  };

  # Workaround for NixOS/nixpkgs#410857 until backport of #475089 lands
  systemd.services.podman-shlink = {
    after = [ "postgresql-setup.service" ];
    requires = [ "postgresql-setup.service" ];
    serviceConfig.Delegate = true;
  };

  virtualisation.oci-containers.containers.shlink-web-client = {
    image = "shlinkio/shlink-web-client:4.7.0";
    podman.user = "podman";
    ports = [ "127.0.0.1:8081:8080" ];
  };

  # Workaround for NixOS/nixpkgs#410857 until backport of #475089 lands
  systemd.services.podman-shlink-web-client.serviceConfig.Delegate = true;
}
