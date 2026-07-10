{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common
  ];

  networking.hostName = "desktop";
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.lew = {
    extraGroups = [ "networkmanager" ];
    initialPassword = "nixos";
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    firefox
    claude-code
  ];

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb.layout = "gb";

  system.stateVersion = "26.05";
}
