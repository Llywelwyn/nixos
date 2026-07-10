{ config, inputs, ... }:
{
  flake.nixosConfigurations.pc0 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      config.flake.modules.nixos.base
      config.flake.modules.nixos.desktop
      ./_pc0-hardware.nix
      ({ config, ... }: {
        networking.hostName = "pc0";
        users.users.l.initialPassword = "nixos";

        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia = {
          modesetting.enable = true;
          nvidiaSettings = true;
          open = false;
          # GTX 1080 (Pascal): dropped from mainline 595+, needs legacy branch
          package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        };
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };

        home-manager.users.l.home.stateVersion = "26.05";
        system.stateVersion = "26.05";
      })
    ];
  };
}
