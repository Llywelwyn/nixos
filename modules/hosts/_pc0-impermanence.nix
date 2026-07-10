{ config, lib, pkgs, ... }:
let
  device = "/dev/disk/by-uuid/26523e8e-e131-4f5f-bd37-4e94268dca17";
  deviceUnit = "dev-disk-by\\x2duuid-26523e8e\\x2de131\\x2d4f5f\\x2dbd37\\x2d4e94268dca17.device";
in
{
  boot.initrd.systemd.initrdBin = with pkgs; [
    btrfs-progs
    findutils
    util-linux
  ];
  boot.initrd.systemd.services.rollback = {
    description = "Wipe ephemeral btrfs subvolumes (/ and /home)";
    wantedBy = [ "initrd.target" ];
    requires = [ deviceUnit ];
    after = [ deviceUnit ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /btrfs_tmp
      mount -o subvol=/ ${device} /btrfs_tmp

      delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
      }

      for subvol in @ @home; do
        if [ -e "/btrfs_tmp/$subvol" ]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y "/btrfs_tmp/$subvol")" "+%Y-%m-%d_%H-%M-%S")
          mv "/btrfs_tmp/$subvol" "/btrfs_tmp/old_roots/''${subvol}_$timestamp"
        fi
        btrfs subvolume create "/btrfs_tmp/$subvol"
      done

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +14); do
        delete_subvolume_recursively "$i"
      done

      umount /btrfs_tmp
    '';
  };

  sops.age.sshKeyPaths = lib.mkForce [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  users.mutableUsers = false;
  sops.secrets.l-password = {
    sopsFile = ../../secrets/users.yaml;
    neededForUsers = true;
  };
  users.users.l.hashedPasswordFile = config.sops.secrets.l-password.path;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      "/var/db/sudo/lectured"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
    users.l = {
      directories = [
        "Projects"
        {
          directory = ".ssh";
          mode = "0700";
        }
        ".config/claude"
        ".config/mozilla"
        ".config/sops"
        ".local/share/direnv"
        ".local/share/fish"
        ".local/share/kwalletd"
        ".local/share/nvim"
        ".local/share/zoxide"
        ".local/state/nvim"
        ".local/share/Steam"
        ".steam"
      ];
    };
  };

  environment.persistence."/data" = {
    hideMounts = true;
    users.l.directories = [
      "Documents"
      "Downloads"
      "Music"
      "Pictures"
      "Videos"
    ];
  };

  home-manager.users.l.home.sessionVariables.CLAUDE_CONFIG_DIR = "/home/l/.config/claude";
}
