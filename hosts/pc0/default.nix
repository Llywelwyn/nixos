{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common
    ./nvidia.nix
    ./steam.nix
    ./gamemode.nix
    ./openssh.nix
    ./sops.nix
  ];

  networking.hostName = "pc0";
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.lew = {
    extraGroups = [ "networkmanager" ];
    initialPassword = "nixos";
  };

  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    firefox
    claude-code
  ];

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb.layout = "gb";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.lew = import ./home;
  };

  system.stateVersion = "26.05";
}
