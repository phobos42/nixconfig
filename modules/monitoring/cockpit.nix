{
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      "WebService" = {
        Origins = "https://cockpit.home.garrettruffner.com https://cockpit.tailnethome.garrettruffner.com";
      };
    };
  };
}
