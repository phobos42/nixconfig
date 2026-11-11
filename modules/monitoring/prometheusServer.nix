{ config, pkgs, ... }:
let
  portNumber = 9001;
  dataDirectory = "/tank/services/prometheus";
  stateDirectory = "/var/lib/${config.services.prometheus.stateDir}";
  tsdbDirectory = "${stateDirectory}/data";
in
{
  # https://wiki.nixos.org/wiki/Prometheus
  # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters-configuration
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/default.nix
  services.prometheus = {
    enable = true;
    port = portNumber;
    globalConfig.scrape_interval = "10s";
    globalConfig.evaluation_interval = "10s";
    checkConfig = "syntax-only";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            labels.host = config.networking.hostName;
          }
        ];
      }
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString portNumber}" ];
            labels.host = config.networking.hostName;
          }
        ];
      }
      {
        job_name = "homeassistant";
        metrics_path = "/api/prometheus";
        authorization = {
          type = "Bearer";
          credentials_file = config.sops.secrets.homeassistantPrometheusToken.path;
        };
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.home-assistant.config.http.server_port}" ];
            labels.host = config.networking.hostName;
          }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}" ];
            labels.host = config.networking.hostName;
          }
        ];
      }
    ];
  };

  systemd.services.prometheus-storage-setup = {
    description = "Prepare Prometheus storage on the ZFS pool";
    before = [ "prometheus.service" ];
    requiredBy = [ "prometheus.service" ];
    unitConfig.RequiresMountsFor = [ dataDirectory ];
    path = with pkgs; [ coreutils findutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail

      old_data=${tsdbDirectory}
      new_data=${dataDirectory}
      old_backup=${tsdbDirectory}.migrated

      echo "Preparing Prometheus TSDB storage at $new_data"
      mkdir -p "$(dirname "$old_data")" "$new_data"
      chown prometheus:prometheus "$new_data"
      chmod 0750 "$new_data"

      if [ -L "$old_data" ]; then
        linked_data=$(readlink -f "$old_data")
        if [ "$linked_data" = "$new_data" ]; then
          echo "Prometheus TSDB already uses $new_data"
          exit 0
        fi
        if [ -e "$old_backup" ]; then
          echo "Refusing to overwrite the previous Prometheus data backup: $old_backup" >&2
          exit 1
        fi

        if [ -d "$linked_data" ]; then
          old_has_data=$(find "$linked_data" -mindepth 1 -maxdepth 1 -print -quit)
          new_has_data=$(find "$new_data" -mindepth 1 -maxdepth 1 -print -quit)
          if [ -n "$old_has_data" ] && [ -n "$new_has_data" ]; then
            echo "Both linked and configured Prometheus data directories contain files; refusing to merge them." >&2
            exit 1
          fi
          if [ -n "$old_has_data" ]; then
            echo "Migrating Prometheus TSDB data from $linked_data"
            cp -a "$linked_data/." "$new_data/"
          fi
        elif [ -e "$linked_data" ]; then
          echo "Prometheus data symlink target is not a directory: $linked_data" >&2
          exit 1
        fi

        chown -R prometheus:prometheus "$new_data"
        mv "$old_data" "$old_backup"
        ln -s "$new_data" "$old_data"
        echo "Prometheus TSDB now uses $new_data; previous symlink preserved at $old_backup"
        exit 0
      fi

      if [ -e "$old_data" ]; then
        if [ ! -d "$old_data" ]; then
          echo "Prometheus data path exists and is not a directory: $old_data" >&2
          exit 1
        fi
        if [ -e "$old_backup" ]; then
          echo "Refusing to overwrite the previous Prometheus data backup: $old_backup" >&2
          exit 1
        fi

        old_has_data=$(find "$old_data" -mindepth 1 -maxdepth 1 -print -quit)
        new_has_data=$(find "$new_data" -mindepth 1 -maxdepth 1 -print -quit)
        if [ -n "$old_has_data" ] && [ -n "$new_has_data" ]; then
          echo "Both Prometheus data directories contain files; refusing to merge them." >&2
          exit 1
        fi
        if [ -n "$old_has_data" ]; then
          echo "Migrating Prometheus TSDB data from $old_data"
          cp -a "$old_data/." "$new_data/"
          chown -R prometheus:prometheus "$new_data"
        elif [ -n "$new_has_data" ]; then
          chown -R prometheus:prometheus "$new_data"
        fi

        mv "$old_data" "$old_backup"
      else
        chown -R prometheus:prometheus "$new_data"
      fi

      ln -s "$new_data" "$old_data"
      echo "Prometheus TSDB now uses $new_data"
    '';
  };

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [
    {
      name = "prometheus";
      value = {
        url = "http://127.0.0.1:${toString portNumber}";
      };
    }
  ];
}
