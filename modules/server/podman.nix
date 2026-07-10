{
  flake.modules.nixos.server = {
    users = {
      users.podman = {
        isSystemUser = true;
        group = "podman";
        home = "/var/lib/podman";
        createHome = true;
        uid = 900;
        linger = true;
        subUidRanges = [{ startUid = 100000; count = 65536; }];
        subGidRanges = [{ startGid = 100000; count = 65536; }];
      };
      groups.podman = {};
    };

    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
