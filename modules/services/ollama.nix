{ pkgs-unstable, ... }:
let
  portNumber = 11434;
in
{
  services.ollama = {
    package = pkgs-unstable.ollama;
    enable = true;
    listenAddress = "127.0.0.1:${toString portNumber}";
    home = "/ollama";
    models = "/ollama";
    writablePaths = [ "/ollama" ];
    sandbox = true;
    acceleration = "cuda";
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "ollama";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}
