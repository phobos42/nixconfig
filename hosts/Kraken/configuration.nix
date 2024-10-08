{ config, pkgs, inputs, ... }:
{
  imports = with inputs.self.nixosModules;
    [
      ./hardware-configuration.nix
      ./disks.nix
      ./config/traefik.nix
      ./config/pia-config.nix
      ./config/tailscale.nix
      users-box
      users-deploy
      mixins-openssh
      mixins-common
      mixins-nm
      mixins-tlp
      profiles-docker
      profiles-libvirtd
      profiles-zfs
      services-nextcloud
      services-jellyfin
      services-deluge
      services-radarr
      services-jackett
      services-sonarr
      services-cockpit
      services-udisks2
      services-syncthing
      services-vaultwarden
      services-ollama
      services-openwebui
      containers-scrutiny
      containers-homarr
    ];

  # _module.args = {
  #   nixinate = {
  #     host = "192.168.1.101";
  #     sshUser = "box";
  #     buildOn = "remote";
  #     substituteOnTarget = true;
  #     hermetic = false;
  #   };
  # };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  networking = {
    hostName = "Kraken";
    defaultGateway = {
      interface = "enp3s0";
    };
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

  environment.systemPackages = with pkgs; [
    wget
    powertop
    gnumake
    smartmontools
    zfs
    rsync
  ];


  users.groups.media = { };
  users.groups.secure = { };
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  system.stateVersion = "23.11";
}
