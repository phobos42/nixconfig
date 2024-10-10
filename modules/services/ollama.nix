{
  services.ollama = {
    enable = true;
    listenAddress = "127.0.0.1:11434";
    home = "/ollama";
    models = "/ollama";
    writablePaths = [
      "/ollama"
    ];
    sandbox  = true;
    acceleration = null;
  };
}