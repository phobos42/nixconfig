{ pkgs, ... }:
{
  services.open-webui = {
    package = pkgs.open-webui;
    enable = true;
    port = 1398;
  };
}
