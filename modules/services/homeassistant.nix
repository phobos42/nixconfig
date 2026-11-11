{ config, ... }:
let portNumber = 8123;
in {
  nixpkgs.overlays = [
    (finalPkgs: prevPkgs: {
      python314 = prevPkgs.python314.override {
        packageOverrides = pythonFinal: pythonPrev: {
          "urllib3-future" = pythonPrev."urllib3-future".overridePythonAttrs (oldAttrs: {
            disabledTestPaths = (oldAttrs.disabledTestPaths or [ ]) ++ [
              "test/test_async_response.py::TestAsyncResponse::test_chunked_decoding_gzip_swallow_garbage"
              "test/test_response.py::TestResponse::test_chunked_decoding_gzip_swallow_garbage"
              "test/test_ssltransport.py::SingleTLSLayerTestCase::test_start_closed_socket"
            ];
          });
        };
      };
    })
  ];

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
      "calendar"
      "caldav"
      "jellyfin"
      "prometheus"
      "ipp"
      "mqtt"
    ];
    extraPackages = python312Packages: with python312Packages; [
      zha
      pyatv
      pychromecast
      getmac
      androidtvremote2
      zwave-js-server-python
      gtts
      caldav
      icalendar
      jellyfin-apiclient-python
      prometheus-client
      pyipp
      paho-mqtt
      aiohasupervisor
      aioesphomeapi
      #aiousbwatcher
      bleak
      bleak-esphome
      bleak-retry-connector
      bluetooth-adapters
      bluetooth-auto-recovery
      bluetooth-data-tools
      dbus-fast
      esphome-dashboard-api
      ha-ffmpeg
      habluetooth
      hassil
      home-assistant-intents
      ifaddr
      mutagen
      pymicro-vad
      pyserial
      pyspeex-noise
      zeroconf
    ];

    configWritable = true;
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };

      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene= "!include scenes.yaml";

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
  services.tlp = {
    enable = true;
    settings = {
      # RUNTIME_PM_DISABLE="00:14.0";
      # USB_DENYLIST="1a86:55d4";
    };
  };
  services.traefik-wrapper.service-definitions = builtins.listToAttrs [{
      name = "homeassistant";
      value = {
        url = "http://192.168.1.101:${toString portNumber}";
        public = true;
      };
    }
  ];
}
