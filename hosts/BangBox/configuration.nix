{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = with inputs.self.nixosModules; [
    ./hardware-configuration.nix
    ./config/tailscale.nix
    ./config/traefik.nix
    ./config/zwavejs.nix
    users-box
    users-deploy
    mixins-openssh
    mixins-common
    mixins-nm
    mixins-tlp
    profiles-libvirtd
    profiles-docker
    containers-pihole
    containers-flame
    # profiles-podman
    containers-homeassistant
  ];

  # _module.args = {
  #   nixinate = {
  #     host = "192.168.1.102";
  #     sshUser = "deploy";
  #     buildOn = "remote";
  #     substituteOnTarget = true;
  #     hermetic = false;
  #   };
  # };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "BangBox";
    defaultGateway = {
      interface = "enp0s20u1";
    };
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

  system.stateVersion = "23.11";
}
