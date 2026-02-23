{ lib, ... }:
let portNumber = 8888;
in {
  services.zrepl = {
    enable = true;
    settings = {
      global = {
        logging = [{
          type = "syslog";
          level = "info";
          format = "human";
        }];
      };
      jobs = [{
          name = "kraken_sink";
          type = "sink";
          root_fs = "tank";
          serve = {
            type = "tcp";
            listen = ":8888";
            listen_freebind = true;
            clients = {
              "100.107.9.38" = "kraken_to_perdido";
            };
          };
          recv = { placeholder = { encryption = "inherit"; }; };
        }];
    };
  };
}
