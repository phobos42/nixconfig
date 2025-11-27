{ config, pkgs, inputs, ... }: {
  nixpkgs.config.allowUnfree = true;
  imports = with inputs.self.nixosModules; [
    ./hardware-configuration.nix
    ./disks.nix
    ./config/traefik-config.nix
    ./config/pia-config.nix
    ./config/sops.nix
    ./config/networkconfig.nix
    users-box
    users-deploy
    mixins-openssh
    mixins-common
    mixins-tlp
    mixins-tailscale
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
    # services-ollama
    # services-openwebui
    services-immich
    services-zfs-replication
    monitoring-scrutiny
    monitoring-udisks2
    monitoring-homarr
    monitoring-cockpit
    monitoring-prometheusExporter
    monitoring-prometheusServer
    usermodules-default
    monitoring-grafana
    #Migration
    containers-pihole
    services-homeassistant
    services-mosquitto
    services-esphome
    ./config/zwavejs.nix
  ];

  # Data Backups
  services.zfs.autoSnapshot.flags = "-k -p --utc";
  services.zfs.autoSnapshot.enable = true;
  services.zfs.autoSnapshot.daily = 30;

  # ZFS Replication to remote host (runs 1 hour after snapshots are created)
  services.zfs-replication = {
    enable = true;
    remoteUser = "box";
    remoteHost = "perdido.kamori-hops.ts.net";  # Update with your remote host IP/hostname
    remotePool = "tank";
    datasets = [
      "tank/services"
      "tank/shack/cloud/immich"
      "tank/shack/cloud/nextcloud"
      "tank/shack/cloud/syncthing"
      "tank/shack/cloud/vaultwarden"
    ];
    schedule = "04:00";  # 4 AM (1 hour after snapshots at 3 AM)
    user = "root";
  };

  # _module.args = {
  #   nixinate = {
  #     host = "192.168.1.101";
  #     sshUser = "box";
  #     buildOn = "remote";
  #     substituteOnTarget = true;
  #     hermetic = false;
  #   };
  # };
  # nixpkgs.config.allowUnsupportedSystem = true; 

  # Use the systemd-boot EFI boot loader.
  boot.initrd.kernelModules = [ "amdgpu" ]; # "nvidia" ];
  # boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.videoDrivers = [
    # "nvidia"
    "amdgpu"
  ];
  hardware.opengl = {
    enable = true;
    # driSupport = true;
    driSupport32Bit = true;
  };

  nixpkgs.config.permittedInsecurePackages =
    [ "dotnet-sdk-6.0.428" "aspnetcore-runtime-6.0.36" "python3.12-ecdsa-0.19.1" "nextcloud-30.0.17"];

  # hardware.nvidia = {
  #   # Modesetting is required.
  #   modesetting.enable = true;

  #   # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
  #   # Enable this if you have graphical corruption issues or application crashes after waking
  #   # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
  #   # of just the bare essentials.
  #   powerManagement.enable = true;

  #   prime = {
  #     offload = {
  #       enable = true;
  #     };
  #     # Make sure to use the correct Bus ID values for your system!
  #     amdgpuBusId = "PCI:6:0:0";
  #     nvidiaBusId = "PCI:1:0:0";
  #   };

  #   # Fine-grained power management. Turns off GPU when not in use.
  #   # Experimental and only works on modern Nvidia GPUs (Turing or newer).
  #   powerManagement.finegrained = true;

  #   # Use the NVidia open source kernel module (not to be confused with the
  #   # independent third-party "nouveau" open source driver).
  #   # Support is limited to the Turing and later architectures. Full list of 
  #   # supported GPUs is at: 
  #   # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
  #   # Only available from driver 515.43.04+
  #   # Currently alpha-quality/buggy, so false is currently the recommended setting.
  #   open = false;

  #   # Enable the Nvidia settings menu,
  #   # accessible via `nvidia-settings`.
  #   nvidiaSettings = true;

  #   # Optionally, you may need to select the appropriate driver version for your specific GPU.
  #   package = config.boot.kernelPackages.nvidiaPackages.latest;
  # };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
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
