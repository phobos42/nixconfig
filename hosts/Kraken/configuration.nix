{
  config,
  pkgs,
  inputs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  imports = with inputs.self.nixosModules; [
    ./hardware-configuration.nix
    ./disks.nix
    ./config/traefik-config.nix
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
    services-syncthing
    services-vaultwarden
    services-ollama
    services-openwebui
    monitoring-scrutiny
    monitoring-udisks2
    monitoring-homarr
    monitoring-cockpit
    monitoring-prometheusExporter
    monitoring-prometheusServer
    usermodules-default
    monitoring-grafana
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
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    prime = {
      offload = {
        enable = true;
      };
      # Make sure to use the correct Bus ID values for your system!
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

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
