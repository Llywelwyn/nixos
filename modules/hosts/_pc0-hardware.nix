{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" ];
    kernelModules = [ "kvm-amd" ];
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/26523e8e-e131-4f5f-bd37-4e94268dca17";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
      neededForBoot = true;
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/26523e8e-e131-4f5f-bd37-4e94268dca17";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };
    "/persist" = {
      device = "/dev/disk/by-uuid/26523e8e-e131-4f5f-bd37-4e94268dca17";
      fsType = "btrfs";
      options = [ "subvol=@persist" ];
      neededForBoot = true;
    };
    "/data" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [ "compress=zstd" "nofail" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/52A0-A4AA";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };

  swapDevices = [
    {
      device = "/persist/swapfile";
      size = 8 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
