{ config, lib, username, ... }:
{
  services.openssh.hostKeys = [
    {
      type = "ed25519";
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
    }
  ];
  sops.age = {
    sshKeyPaths = lib.mkForce [ ];
    keyFile = "/home/${username}/.config/sops/age/keys.txt";
  };
  home-manager.users.${username}.sops.age = {
    sshKeyPaths = lib.mkForce [ ];
    keyFile = "/home/${username}/.config/sops/age/keys.txt";
  };

  sops.secrets."${username}-password" = {
    sopsFile = ../../secrets/users.yaml;
    neededForUsers = true;
  };
  users = {
    mutableUsers = false;
    users.${username} = {
      uid = 1000;
      hashedPasswordFile = config.sops.secrets."${username}-password".path;
    };
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      "/var/db/sudo/lectured"
      "/var/lib/AccountsService"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/sddm"
      "/var/lib/systemd"
      "/var/log"
      {
        directory = "/var/tmp";
        mode = "1777";
      }
    ];
    files = [ "/etc/machine-id" ];
  };
}
