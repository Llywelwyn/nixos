{ config, ... }:
{
  sops.secrets.tinyauth-users = {
    sopsFile = ../../secrets/tinyauth.yaml;
    owner = "podman";
  };

  services.caddy.extraConfig = ''
    (tinyauth) {
      forward_auth localhost:3002 {
        uri /api/auth/caddy
        copy_headers Remote-User Remote-Name Remote-Email Remote-Groups
      }
    }
  '';

  services.caddy.virtualHosts."auth.ily.rs" = {
    extraConfig = ''
      reverse_proxy localhost:3002
      encode zstd gzip
    '';
  };

  virtualisation.oci-containers.containers.tinyauth = {
    image = "ghcr.io/steveiliop56/tinyauth:v5.0.6";
    podman.user = "podman";
    volumes = [
      "/srv/tinyauth/data:/data"
      "${config.sops.secrets.tinyauth-users.path}:/data/users:ro"
    ];
    ports = [ "127.0.0.1:3002:3000" ];
    environment = {
      TINYAUTH_APPURL = "https://auth.ily.rs";
      TINYAUTH_AUTH_USERSFILE = "/data/users";
      TINYAUTH_AUTH_SECURECOOKIE = "true";
      TINYAUTH_AUTH_TRUSTEDPROXIES = "127.0.0.1";
      TINYAUTH_ANALYTICS_ENABLED = "false";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/tinyauth/data 0750 podman podman -"
  ];

  systemd.services.podman-tinyauth.serviceConfig.Delegate = true;
}
