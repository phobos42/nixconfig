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
      jobs = [
        {
          name = "kraken_sink";
          type = "sink";
          root_fs = "tank";
          serve = {
            type = "tcp";
            listen = ":${toString portNumber}";
            listen_freebind = true;
            clients = { "100.107.9.38" = "kraken_to_perdido"; };
          };
          recv = { placeholder = { encryption = "inherit"; }; };
        }
        {
          name = "perdido_to_kraken";
          type = "push";
          connect = {
            type = "tcp";
            address = "kraken.kamori-hops.ts.net:${toString portNumber}";
          };
          filesystems = {
            "tank<" = false;
            "tank/dr<" = true;
          };
          snapshotting = {
            type = "periodic";
            prefix = "zrepl_";
            timestamp_format = "iso-8601";
            interval = "15m";
          };
          send = {
            encrypted = false;
            compressed = true;
          };
          pruning = {
            keep_sender = [
              { type = "not_replicated"; }
              {
                type = "last_n";
                count = 10;
              }
              {
                type = "grid";
                grid = "1x3h(keep=all) | 2x6h | 30x1d | 6x30d | 1x365d";
                regex = "^zrepl_.*";
              }
              {
                type = "regex";
                negate = true;
                regex = "^zrepl_.*";
              }
            ];
            keep_receiver = [{
              type = "grid";
              grid = "1x3h(keep=all) | 2x6h | 30x1d | 6x30d | 1x365d";
              regex = "^zrepl_.*";
            }];
          };
        }
      ];
    };
  };
}
