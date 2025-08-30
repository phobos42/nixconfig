{ config, pkgs, inputs, modulesPath, lib, ... }: {
  nixpkgs.config.allowUnfree = true;
  imports = with inputs.self.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ./disk-config.nix
    ./config/sops.nix
    ./config/traefik-config.nix
    users-box
    users-deploy
    usermodules-default
    mixins-openssh
    mixins-common
    mixins-nm
    mixins-tlp
    mixins-tailscale
    profiles-zfs
    monitoring-cockpit
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "Perdido";
    defaultGateway = { interface = "enp0s31f6"; };
    interfaces.enp0s31f6 = { useDHCP = true; };
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  environment.systemPackages = with pkgs; [
    curl
    gitMinimal
    wget
    powertop
    gnumake
    smartmontools
    zfs
    rsync
  ];
  system.stateVersion = "24.05";
}
