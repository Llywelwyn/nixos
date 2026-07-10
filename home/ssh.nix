{ config, ... }:
{
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  sops.secrets.ssh_config = {
    sopsFile = ../secrets/ssh.yaml;
    path = "${config.home.homeDirectory}/.ssh/config";
  };
}
