{ config, ... }:
{
  flake.modules.nixos.tcz = { pkgs, ... }: {
    home-manager.users.${config.flake.meta.username}.home.packages = with pkgs; [
      dart-sass
      dotnet-sdk_9
      lessc
      nodejs
      stripe-cli
    ];

    virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.tcz-mongo = {
        image = "docker.io/library/mongo:7";
        autoStart = false;
        extraOptions = [ "--memory=2g" ];
        ports = [ "127.0.0.1:27017:27017" ];
        volumes = [
          "/var/lib/tcz-mongo/db:/data/db"
          "/var/lib/tcz-mongo/configdb:/data/configdb"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/tcz-mongo/db 0755 root root -"
      "d /var/lib/tcz-mongo/configdb 0755 root root -"
    ];

    environment.persistence."/persist".directories = [
      "/var/lib/containers"
      "/var/lib/tcz-mongo"
    ];

    environment.systemPackages = with pkgs; [
      mongosh
      mongodb-tools
    ];
  };
}
