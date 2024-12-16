{ pkgs, config, lib, ... }:
{
  networking.hostId = "915bb6c9";
  services.zfs.autoScrub.enable = true;
  boot = {
    # kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    supportedFilesystems = [ "zfs" ];
  };
}

