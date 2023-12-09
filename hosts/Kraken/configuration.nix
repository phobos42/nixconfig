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
      profiles-libvirtd
      mixins-nm
    ];
  _module.args = {
    nixinate = {
      host = "Kraken";
      sshUser = "box";
      buildOn = "remote";
      substituteOnTarget = true;
      hermetic = false;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking = {
    hostName = "Kraken";
    interfaces.enp3s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.101";
          prefixLength = 24;
        }
      ];
    };
  };

  time.timeZone = "America/Chicago";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    #keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };
  # users.users.box = {
  #   isNormalUser = true;
  #   hashedPassword = "$6$x4R//6ix5xhSUKMI$Tu6jkZJOcRQo6UGVtcvZq.1N7SGibdZtkVfavKuaKYVNReeOGITTKlpYgQxGXc.KrQ8CWT5DKgydUKKz9hvGp.";
  #   extraGroups = [ "wheel" "networkmanager" ];
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };
  # users.users.root = {
  #   hashedPassword = "$6$yrxZjj0o4Bt0//o5$hg1V.GckF/TgTqV4XenuI00DR6k1PlzKYHoUKsjl2CBTZepdAMNOz6xYEeMNP.I.xK0YlN6p.d6llhUgIeNig1";
  # };
  environment.systemPackages = with pkgs; [
    wget
    powertop
    gnumake
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

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
