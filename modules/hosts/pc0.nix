{ config, inputs, ... }:
let
  inherit (config.flake.meta) username;
in
{
  flake.nixosConfigurations.pc0 = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit username; };
    modules = [
      config.flake.modules.nixos.base
      config.flake.modules.nixos.desktop
      inputs.impermanence.nixosModules.impermanence
      ./_pc0-hardware.nix
      ./_pc0-impermanence.nix
      ./_pc0-tcz-mongo.nix
      {
        networking.hostName = "pc0";

        hardware = {
          amdgpu.initrd.enable = true;
          graphics = {
            enable = true;
            enable32Bit = true;
          };
          bluetooth.enable = true;
        };

        services = {
          # Source-only. We don't want devices using this PC *as* a speaker.
          pipewire.wireplumber.extraConfig."50-bluez-roles" = {
            "monitor.bluez.properties"."bluez5.roles" = [ "a2dp_source" "hfp_ag" ];
          };

          btrfs.autoScrub = {
            enable = true;
            fileSystems = [ "/persist" "/data" ];
          };
        };

        home-manager.users.${username}.home.stateVersion = "26.05";
        system.stateVersion = "26.05";
      }
    ];
  };
}
