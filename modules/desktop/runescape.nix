{
  flake.modules.nixos.desktop = {
    nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
  };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      runelite
      (bolt-launcher.override { enableRS3 = true; })
    ];
  };
}
