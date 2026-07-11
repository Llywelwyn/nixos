{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      runelite
      bolt-launcher
    ];
  };
}
