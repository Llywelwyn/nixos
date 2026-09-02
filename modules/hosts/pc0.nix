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
      config.flake.modules.nixos.tcz
      inputs.impermanence.nixosModules.impermanence
      ./_pc0-hardware.nix
      ./_pc0-impermanence.nix
      ({ pkgs, ... }: {
        networking.hostName = "pc0";

        # 0x20000 = DC_DISABLE_SUBVP_FAMS; its phantom-plane path NULL-derefs
        boot.kernelParams = [ "amdgpu.dcdebugmask=0x20000" ];

        hardware = {
          amdgpu.initrd.enable = true;
          graphics = {
            enable = true;
            enable32Bit = true;
          };
          bluetooth.enable = true;
        };

        services = {
          # -S 120 = standby after 10 min idle (units of 5 s)
          udev.extraRules = ''
            ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{model}=="ST1000DM003*", RUN+="${pkgs.hdparm}/bin/hdparm -S 120 /dev/%k"
          '';

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
      })
    ];
  };
}
