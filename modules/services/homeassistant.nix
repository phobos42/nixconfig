{ config, ... }:
let portNumber = 8123;
in {
  services.home-assistant = {
    enable = true;


    extraComponents = [
      # Components required to complete the onboarding
      "cast"
      "esphome"
      "met"
      "radio_browser"
      "zha"
      "zwave_js"
      "apple_tv"
      "androidtv"
      "androidtv_remote"
      "upnp"
      "shopping_list"
      "isal"
    ];
    extraPackages = python312Packages: with python312Packages; [
      zha
      pyatv
      pychromecast
      getmac
      androidtvremote2
      zwave-js-server-python
      gtts
    ];

    configWritable = true;
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      http = {
        # server_host = "::1";
        trusted_proxies = [ "192.168.1.0/24" ];
        use_x_forwarded_for = true;
        server_port = portNumber;

      };
    };
    customComponents = [

    ];
    
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [{
      name = "homeassistant";
      value = {
        url = "http://192.168.1.102:${toString portNumber}";
      };
    }
  ];
}
