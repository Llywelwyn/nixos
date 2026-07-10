{
  flake.modules.nixos.desktop = {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
    programs.gamemode.enable = true;
  };
}
