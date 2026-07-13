{
  flake.modules.nixos.server = { pkgs, ... }: {
    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;
    security.sudo.wheelNeedsPassword = false;
    services.journald.extraConfig = ''
      SystemMaxUse=500M
    '';
    environment.systemPackages = with pkgs; [
      sqlite
    ];
  };
}
