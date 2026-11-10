{ config, lib, pkgs, ... }:
let
  cfg = config.services.cloudflared-wrapper;
  tokenSecretName = "cloudflared-${cfg.tunnelId}-token";
in
with lib;
{
  options.services.cloudflared-wrapper = {
    enable = mkEnableOption "Cloudflare Tunnel connector";
    tunnelId = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "UUID of the remotely managed Cloudflare Tunnel.";
    };
    tokenSopsFile = mkOption {
      type = types.path;
      default = ../../hosts/common.yaml;
      description = "SOPS YAML file containing this host's tunnel token.";
    };
    tokenSopsKey = mkOption {
      type = types.str;
      default = "cloudflared_${lib.strings.toLower config.networking.hostName}_token";
      description = "Key in the SOPS YAML file containing this host's tunnel token.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tunnelId != null;
        message = "services.cloudflared-wrapper.tunnelId must be set when enabled.";
      }
    ];

    sops.secrets.${tokenSecretName} = {
      sopsFile = cfg.tokenSopsFile;
      format = "yaml";
      key = cfg.tokenSopsKey;
      restartUnits = [ "cloudflared.service" ];
    };

    systemd.services.cloudflared = {
      description = "Cloudflare Tunnel connector ${cfg.tunnelId}";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        LoadCredential = [
          "tunnel-token:${config.sops.secrets.${tokenSecretName}.path}"
        ];
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file %d/tunnel-token";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
      };
    };
  };
}