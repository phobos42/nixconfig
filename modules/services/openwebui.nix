{ pkgs, ... }:
{
  # environment.systemPackages = [ unstablepkgs.open-webui ];
  services.open-webui = {
    package = pkgs.open-webui;
    enable = true;
    port = 1398;
  };
}
