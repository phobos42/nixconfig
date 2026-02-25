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
          name = "kraken_to_perdido";
          type = "push";
          connect = {
            type = "tcp";
            address = "perdido.kamori-hops.ts.net:8888";
          };
          filesystems = {
            "tank<" = false;
            "tank/services<" = true;
            "tank/shack<" = false;
            "tank/shack/cloud<" = false;
            "tank/shack/cloud/immich<" = true;
            "tank/shack/cloud/nextcloud<" = true;
            "tank/shack/cloud/syncthing<" = true;
            "tank/shack/cloud/vaultwarden<" = true;
            "tank/shack/cloud/tube<" = false;
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
        {
          name = "perdido_sink";
          type = "sink";
          root_fs = "tank";
          serve = {
            type = "tcp";
            listen = ":${toString portNumber}";
            listen_freebind = true;
            clients = { "100.105.7.3" = "perdido_to_kraken"; };
          };
          recv = { placeholder = { encryption = "inherit"; }; };
        }
      ];
    };
  };
}

# TODO zrepl monitor
#monitoring = [
#  {
#    type = "prometheus";
#    listen = ":9811";
#    listen_freebind = true;
#  }
#];
