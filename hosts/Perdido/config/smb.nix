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
      };
    };
    # extraConfig = ''
    #   workgroup = ATLAS
    #   server string = smbnix
    #   server role = standalone server
    # '';
    shares = {
      home = {
        path = "/tank/dr/smb/shared";
        "guest ok" = "yes";
        public = "yes";
        writable = "yes";
        printable = "no";
        browseable = "yes";
        "read only" = "no";
        comment = "server1 /home/me/ samba share.";
      };
      # server1-data = {
      #   path = "/data/";
      #   "guest ok" = "no";
      #   public = "yes";
      #   writable = "yes";
      #   printable = "no";
      #   browseable = "yes";
      #   "read only" = "no";
      #   comment = "server1 /data/ samba share.";
      # };
    };
  };

  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
    extraOptions = [ "--verbose" ];
  };

  # firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 137 138 139 389 445 ];
  #   allowedUDPPorts = [ 137 138 139 389 445 ];
  # };
  users.users.smbuser = { isNormalUser = true; };
  # Make the samba user "my_user" on the system
  # users.users.smbuser = {
  #   description = "Write-access to samba media shares";
  #   # Add this user to a group with permission to access the expected files 
  #   extraGroups = [ "users" ];
  #   # Password can be set in clear text with a literal string or from a file.
  #   # Using sops-nix we can use the same file so that the system user and samba
  #   # user share the same credential (if desired).
  #   hashedPasswordFile = config.sops.secrets.samba.path;
  #   isNormalUser = true;
  # };
  # Set "my_user" as a valid samba login
  # services.samba = {
  #   enable = true;
  #   openFirewall = true;
  #   settings = {
  #     global = {
  #       "server smb encrypt" = "required";
  #       "server min protocol" = "SMB3_00";
  #       "workgroup" = "WORKGROUP";
  #       "security" = "user";
  #     };
  #     my_share_directory = {
  #       "path" = "/tank/dr/smb/shared";
  #       "writable" = "yes";
  #       "guest ok" = "yes";
  #       "comment" = "Hello World!";
  #       "browseable" = "yes";
  #       "valid users" = "smbuser";
  #     };
  #   };
  # };
  # Activation scripts run every time nixos switches build profiles. So if you're
  # pulling the user/samba password from a file then it will be updated during
  # nixos-rebuild. Again, in this example we're using sops-nix with a "samba" entry
  # to avoid cleartext password, but this could be replaced with a static path.
  # system.activationScripts = {
  #   # The "init_smbpasswd" script name is arbitrary, but a useful label for tracking
  #   # failed scripts in the build output. An absolute path to smbpasswd is necessary
  #   # as it is not in $PATH in the activation script's environment. The password
  #   # is repeated twice with newline characters as smbpasswd requires a password
  #   # confirmation even in non-interactive mode where input is piped in through stdin. 
  #   init_smbpasswd.text = ''
  #     /run/current-system/sw/bin/printf "$(/run/current-system/sw/bin/cat ${config.sops.secrets.samba.path})\n$(/run/current-system/sw/bin/cat ${config.sops.secrets.samba.path})\n" | /run/current-system/sw/bin/smbpasswd -sa smbuser
  #   '';
  # };
  # services.samba-wsdd = {
  #   enable = true;
  #   openFirewall = true;
  # };
  # services.avahi = {
  #   enable = true;
  #   publish.enable = true;
  #   publish.userServices = true;
  #   openFirewall = true;
  # };
  # networking.firewall.allowPing = true;
  # sops.secrets = {
  #   samba = {
  #     sopsFile = ./smb.bin;
  #     format = "binary";
  #   };
  # };

  # services = {
  #   samba = {
  #     enable = true;
  #     settings = {
  #       global = {
  #         "workgroup" = "WORKGROUP";
  #         "server string" = "smbnix";
  #         "netbios name" = "smbnix";
  #         "security" = "user";
  #       };

  #       "my_share" = {
  #         "path" = "/tank/dr/smb/shared";
  #         # "valid users" = "box";
  #         "force user" = "box";
  #         # "writable" = "yes";
  #         "guest ok" = "yes";
  #         # "public" = "no";
  #         "writeable" = "yes";
  #         "guest account" = "box";
  #         "create mask" = "0775";
  #         "directory mask" = "0755";
  #       };
  #     };
  #   };

  #   samba-wsdd = {
  #     enable = true;
  #     discovery = true;
  #   };

  #   avahi = {
  #     enable = true;

  #     publish.enable = true;
  #     publish.userServices = true;
  #     nssmdns4 = true;
  #   };
  # };

}

# services.samba = {
#   enable = true;
#   securityType = "user";
#   openFirewall = true;
#   settings = {
#     global = {
#       "workgroup" = "WORKGROUP";
#       "server string" = "smbnix";
#       "netbios name" = "smbnix";
#       "security" = "user";
#       "passdb backend" = "tdbsam";
#       #"use sendfile" = "yes";
#       #"max protocol" = "smb2";
#       # note: localhost is the ipv6 localhost ::1
#       "hosts allow" = "127.0.0.1 100.0.0.0/8 192.168.0.0/16";
#       "hosts deny" = "0.0.0.0/0";
#       "guest account" = "nobody";
#       "map to guest" = "never";
#     };
#     "public" = {
#       "path"          = "/tank/dr/smb/shared";
#       "browseable"    = "yes";
#       "read only"     = "no";
#       "guest ok"      = "yes";
#       "create mask"   = "0644";
#       "directory mask"= "0755";
#       "force user"  = "box";
#       "force group" = "users";
#     };
#   };
# };

# services.samba-wsdd = {
#   enable = true;
#   openFirewall = true;
# };

# networking.firewall.enable = true;
# networking.firewall.allowPing = true;
# }
