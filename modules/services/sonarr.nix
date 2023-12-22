{
  services.sonarr = {
    # Port 8989
    enable = true;
    # openFirewall = true;
  };
  users.users.sonarr.extraGroups = [ "media" ];
}
