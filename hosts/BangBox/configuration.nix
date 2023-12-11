# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, ... }:

{
  imports = with inputs.self.nixosModules; 
    [
      ./hardware-configuration.nix
      users-box
      mixins-openssh
      mixins-common
      mixins-nm
      mixins-tlp
      profiles-libvirtd
      profiles-docker
      services-flame
    ];

  _module.args = {
    nixinate = {
      host = "BangBox";
      sshUser = "box";
      buildOn = "remote";
      substituteOnTarget = true;
      hermetic = false;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

   networking = {
    hostName = "BangBox";
    interfaces.enp0s20u1 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.102";
          prefixLength = 24;
        }
      ];
    };
  };

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    #    keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # users.mutableUsers = false;
  # users.users.box = {
  #   hashedPassword = "$6$WoXeWZoFr4eGRHae$vnkZcDALT8FKCr.3/DmSuQyO.IC5X0sa79w50KfB0JoTHOvo2mf83kWZGRzBLMNAFd6x/aIRckfzriVoHsIU4/";
  #   isNormalUser = true;
  #   extraGroups = [
  #     "wheel"
  #     "networkmanager"
  #   ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  environment.systemPackages = with pkgs; [
    wget
    powertop
    gnumake
  ];

  services.logind.extraConfig = ''
    	HandleLidSwitch=ignore
    	LidSwitchIgnoreInhibited=no
    	HandleLidSwitchDocked=ignore
    	HandleLidSwitchExternalPower=ignore
  '';

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  system.stateVersion = "23.11";
}

