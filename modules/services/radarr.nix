{
  services.radarr = {
    enable = true;    
  };
  #7878
  users.users.radarr.extraGroups = [ "media" ];
}
