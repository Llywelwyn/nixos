{ config, lib, username, ... }:
{
  services.openssh.hostKeys = [
    {
      type = "ed25519";
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
    }
  ];
  sops.age.sshKeyPaths = lib.mkForce [ "/home/${username}/.ssh/id_ed25519" ];

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
    ];
    files = [ "/etc/machine-id" ];
  };

  systemd.tmpfiles.rules = map (d: "L /home/${username}/${d} - - - - /data/home/${username}/${d}") [
    "documents"
    "downloads"
    "music"
    "pictures"
    "videos"
  ];
}
