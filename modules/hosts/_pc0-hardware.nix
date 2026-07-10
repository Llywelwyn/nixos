{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" ];
    kernelModules = [ "kvm-amd" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/26523e8e-e131-4f5f-bd37-4e94268dca17";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/26523e8e-e131-4f5f-bd37-4e94268dca17";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/26523e8e-e131-4f5f-bd37-4e94268dca17";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/52A0-A4AA";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
