{ config, lib, ... }:
{
  services.openssh.hostKeys = [
    {
      type = "ed25519";
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
    }
  ];
  sops.age.sshKeyPaths = lib.mkForce [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.l-password = {
    sopsFile = ../../secrets/users.yaml;
    neededForUsers = true;
  };
  users = {
    mutableUsers = false;
    users.l = {
      uid = 1000;
      hashedPasswordFile = config.sops.secrets.l-password.path;
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

  systemd.tmpfiles.rules = map (d: "L /home/l/${d} - - - - /data/home/l/${d}") [
    "documents"
    "downloads"
    "music"
    "pictures"
    "videos"
  ];
}
