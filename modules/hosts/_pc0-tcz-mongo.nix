{ pkgs, ... }:
{
  virtualisation.podman.enable = true;
  virtualisation.oci-containers = {
    backend = "podman";
    containers.tcz-mongo = {
      image = "docker.io/library/mongo:7";
      ports = [ "127.0.0.1:27017:27017" ];
      volumes = [
        "/var/lib/tcz-mongo/db:/data/db"
        "/var/lib/tcz-mongo/configdb:/data/configdb"
      ];
    };
  };

  environment.persistence."/persist".directories = [ "/var/lib/tcz-mongo" ];

  environment.systemPackages = with pkgs; [
    mongosh
    mongodb-tools
  ];
}
