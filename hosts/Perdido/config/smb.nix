{ pkgs, config, ... }: {
  services.samba = {
    enable = true;
    package = pkgs.samba4Full;
    securityType = "user";
    invalidUsers = [ "root" ];
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";      
        "hosts allow" = "192.168.0. 127.0.0.1 localhost 100.0.0/8";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
    };
  
    shares = {
      # home = {
      #   path = "/tank/dr/smb/shared";
      #   "guest ok" = "yes";
      #   public = "yes";
      #   writable = "yes";
      #   printable = "no";
      #   browseable = "yes";
      #   "read only" = "no";
      #   comment = "server1 /home/me/ samba share.";
      # };
      public = {
        "path" = "/tank/dr/smb/shared";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "smbuser";
        "force group" = "users";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
    extraOptions = [ "--verbose" ];
  };

  users.users.smbuser = { isNormalUser = true; };
}
