{pkgs, lib, config, ...}:
{
  options = {
    btop.enable = lib.mkEnableOption "Enable btop monitoring utility";
  };  
  config = lib.mkIf config.btop.enable { environment.systemPackages = [ pkgs.btop ]; };
}