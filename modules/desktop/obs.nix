{
  flake.modules.nixos.desktop = {
    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };
  };
}
