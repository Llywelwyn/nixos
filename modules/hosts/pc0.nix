{ config, inputs, ... }:
{
  flake.nixosConfigurations.pc0 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.modules.nixos.base
      config.flake.modules.nixos.desktop
      inputs.impermanence.nixosModules.impermanence
      ./_pc0-hardware.nix
      ./_pc0-impermanence.nix
      ({ config, ... }: {
        networking.hostName = "pc0";

        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia = {
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
