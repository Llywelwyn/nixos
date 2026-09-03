{ config, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }:
    let
      creamlinux = import (pkgs.fetchFromGitHub {
        owner = "Novattz";
        repo = "creamlinux-installer";
        rev = "01bf6fb26121554ca8792b70c3caecb382de13f8";
        hash = "sha256-/e4cXMEQiR8mCn+QmKk700L6PFXLJ+YUw5Mn+FBj6xI=";
      }) { inherit pkgs; };
    in
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        protontricks.enable = true;
      };
      programs.gamemode.enable = true;
      programs.nix-ld.enable = true;
      hardware.xpadneo.enable = true;
      users.users.${config.flake.meta.username}.extraGroups = [ "gamemode" ];
      environment.systemPackages = [ creamlinux ];
    };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    xdg.dataFile."Steam/compatibilitytools.d/GE-Proton".source = pkgs.proton-ge-bin.steamcompattool;
  };
}
