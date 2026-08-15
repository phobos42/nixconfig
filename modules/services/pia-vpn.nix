{ config, lib, pkgs, ... }:
let
  cfg = config.services.pia-vpn;
in
with lib;

{
  options.services.pia-vpn = {
    enable = mkEnableOption "Private Internet Access VPN service.";

    certificateFile = mkOption {
      type = types.path;
      description = ''
        Path to the CA certificate for Private Internet Access servers.

        This is provided as <filename>ca.rsa.4096.crt</filename>.
      '';
    };

    environmentFile = mkOption {
      type = types.path;
      description = ''
        Path to an environment file with the following contents:

        <programlisting>
        PIA_USER=''${username}
        PIA_PASS=''${password}
        </programlisting>
      '';
    };

    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = ''
        WireGuard interface to create for the VPN connection.
      '';
    };

    blacklistedHosts = mkOption {
      type = types.listOf types.str;
      default = [ "Server-11540-3a" ];
      description = ''
        Hostnames to exclude when choosing a PIA server.
        This can be used to avoid a misbehaving server while keeping the rest of the region list available.
      '';
    };

    maxLatency = mkOption {
      type = types.float;
      default = 0.5;
      description = ''
        Maximum latency to allow for auto-selection of VPN server,
        in seconds.
      '';
    };

    preUp = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands called at the start of the interface setup.
      '';
    };

    postUp = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands called at the end of the interface setup.
      '';
    };

    preDown = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands called before the interface is taken down.
      '';
    };

    postDown = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands called after the interface is taken down.
      '';
    };

    portForward = {
      enable = mkEnableOption "port forwarding through the PIA VPN connection.";

      script = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Script to execute, with <varname>$port</varname> set to the forwarded port.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [ "wireguard" ];

    systemd.services.pia-vpn = {
      description = "Connect to Private Internet Access on ${cfg.interface}";
      path = with pkgs; [ bash curl gawk jq openssl wireguard-tools ];
      requires = [ "network-online.target" ];
      # after = [ "network.target" "network-online.target" ];
      after = [ "network.target" "network-online.target" "systemd-resolved.service" ];
      wantedBy = [ "multi-user.target" ];

      unitConfig = {
        ConditionFileNotEmpty = [
          cfg.certificateFile
          cfg.environmentFile
        ];
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        EnvironmentFile = cfg.environmentFile;

        CacheDirectory = "pia-vpn";
        StateDirectory = "pia-vpn";
      };

      script = ''
        echo Determining region...
        serverlist='https://serverlist.piaservers.net/vpninfo/servers/v4'
        blacklistedHosts='${builtins.toJSON cfg.blacklistedHosts}'
        
        # Retry fetching server list with exponential backoff
        allregions=""
        for attempt in {1..5}; do
          >&2 echo "Fetching server list (attempt $attempt/5)..."
          allregions=$(curl -s -f -m 10 "$serverlist" 2>&1)
          if [ $? -eq 0 ]; then
            >&2 echo "Successfully fetched server list"
            break
          fi
          >&2 echo "Failed to fetch server list: $allregions"
          if [ $attempt -lt 5 ]; then
            sleep $((2 ** $attempt))
          fi
        done
        
        if [ -z "$allregions" ]; then
          >&2 echo "Could not fetch server list after 5 attempts"
          exit 1
        fi
        
        # Extract first line (contains all regions)
        allregions=$(echo "$allregions" | head -1)
        
        # Extract servers: for each region, get the meta server IP and connection info
        filtered="$(echo "$allregions" | jq -r --argjson blacklist "$blacklistedHosts" '
                   .regions[]
                   ${optionalString cfg.portForward.enable "| select(.port_forward==true)"}
                   | select(.servers.meta != null and (.servers.meta | length) > 0)
                   | select(.servers.meta[0].cn as $cn | ($blacklist | index($cn) | not))
                   | select(.servers.wg != null and (.servers.wg | length) > 0)
                   | select(.servers.wg[0].cn as $cn | ($blacklist | index($cn) | not))
                   | .servers.meta[0].ip as $ip | .id as $id | .name as $name | (.geo // false) as $geo
                   | "\($ip) \($id) \($name) \($geo)"')"
        
        >&2 echo "Scanning $(echo "$filtered" | grep -c . || echo 0) servers for latency..."
        
        latencies=""
        while IFS= read -r line; do
          [ -z "$line" ] && continue
          serverIP=$(echo "$line" | awk '{print $1}')
          regionID=$(echo "$line" | awk '{print $2}')
          regionName=$(echo "$line" | awk '{print $3, $4}')
          
          time=$(LC_NUMERIC=en_US.utf8 curl -o /dev/null -s \
            --connect-timeout ${toString cfg.maxLatency} \
            --write-out "%{time_connect}" \
            http://$serverIP:443)
          if [ $? -eq 0 ]; then
            >&2 echo Got latency ''${time}s for region: $regionName
            latencies="$latencies
$time $regionID $serverIP"
          fi
        done <<< "$filtered"
        
        best="$(echo "$latencies" | grep -v '^$' | sort | head -1 | awk '{ print $2 }')"
        
        if [ -z "$best" ]; then
          >&2 echo "No region found with latency under ${toString cfg.maxLatency} s. Stopping."
          exit 1
        fi
        region="$(echo $allregions |
                  jq --arg REGION_ID "$best" -r '.regions[] | select(.id==$REGION_ID)')"
        meta_ip="$(echo $region | jq -r '.servers.meta[0].ip')"
        meta_hostname="$(echo $region | jq -r '.servers.meta[0].cn')"
        wg_ip="$(echo $region | jq -r '.servers.wg[0].ip')"
        wg_hostname="$(echo $region | jq -r '.servers.wg[0].cn')"
        echo "$region" > $STATE_DIRECTORY/region.json

        echo Generating token...
        if [ ! -s "${cfg.certificateFile}" ]; then
          >&2 echo "PIA TLS certificate file is missing or empty: ${cfg.certificateFile}"
          exit 1
        fi
        if ! ${pkgs.openssl}/bin/openssl x509 -in "${cfg.certificateFile}" -noout >/dev/null 2>&1; then
          >&2 echo "PIA TLS certificate is not a valid X.509 certificate: ${cfg.certificateFile}"
          exit 1
        fi
        tokenResponse="$(curl -sS --show-error --connect-timeout 15 \
          --connect-to "$meta_hostname::$meta_ip" \
          --cacert "${cfg.certificateFile}" \
          -u "$PIA_USER:$PIA_PASS" \
          "https://$meta_hostname/authv3/generateToken" 2> "$STATE_DIRECTORY/token.err" || {
            rc=$?
            >&2 echo "TLS/auth token request failed (curl exit $rc)."
            >&2 echo "Certificate file: ${cfg.certificateFile}"
            >&2 echo "Target host: $meta_hostname ($meta_ip)"
            >&2 echo "curl stderr:"
            >&2 cat "$STATE_DIRECTORY/token.err"
            exit 1
          })"
        if [ -z "$tokenResponse" ]; then
          >&2 echo "PIA token endpoint returned empty output."
          >&2 echo "curl stderr:"
          >&2 cat "$STATE_DIRECTORY/token.err" 2>/dev/null || true
          exit 1
        fi
        if [ "$(echo "$tokenResponse" | jq -r '.status' 2>/dev/null || echo 'null')" != "OK" ]; then
          >&2 echo "Failed to generate token. Response was not OK."
          >&2 echo "$tokenResponse"
          >&2 echo "curl stderr:"
          >&2 cat "$STATE_DIRECTORY/token.err" 2>/dev/null || true
          exit 1
        fi
        echo "$tokenResponse" > $STATE_DIRECTORY/token.json
        token="$(echo "$tokenResponse" | jq -r '.token')"

        echo Connecting to the PIA WireGuard API on $wg_ip...
        privateKey="$(wg genkey)"
        publicKey="$(echo "$privateKey" | wg pubkey)"
        json="$(curl -sS --show-error --connect-timeout 15 -G \
          --connect-to "$wg_hostname::$wg_ip:" \
          --cacert "${cfg.certificateFile}" \
          --data-urlencode "pt=''${token}" \
          --data-urlencode "pubkey=$publicKey" \
          "https://''${wg_hostname}:1337/addKey" 2> "$STATE_DIRECTORY/wg.err" || {
            rc=$?
            >&2 echo "TLS/WireGuard API request failed (curl exit $rc)."
            >&2 echo "Certificate file: ${cfg.certificateFile}"
            >&2 echo "Target host: $wg_hostname ($wg_ip)"
            >&2 echo "curl stderr:"
            >&2 cat "$STATE_DIRECTORY/wg.err"
            exit 1
          })"
        status="$(echo "$json" | jq -r '.status' 2>/dev/null || echo 'null')"
        if [ "$status" != "OK" ]; then
          >&2 echo "Server did not return OK for addKey."
          >&2 echo "$json"
          >&2 echo "curl stderr:"
          >&2 cat "$STATE_DIRECTORY/wg.err" 2>/dev/null || true
          exit 1
        fi

        echo Creating network interface ${cfg.interface}.
        echo "$json" > $STATE_DIRECTORY/wireguard.json

        gateway="$(echo "$json" | jq -r '.server_ip')"
        servervip="$(echo "$json" | jq -r '.server_vip')"
        peerip=$(echo "$json" | jq -r '.peer_ip')
        server_key=$(echo "$json" | jq -r '.server_key')
        server_port=$(echo "$json" | jq -r '.server_port')

        echo Bringing up network interface ${cfg.interface}.

        ${cfg.preUp}

        # Clean up any existing interface
        ${pkgs.iproute2}/bin/ip route flush table 42 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link delete dev ${cfg.interface} 2>/dev/null || true

        # Create WireGuard interface directly
        if ! ${pkgs.iproute2}/bin/ip link show ${cfg.interface} >/dev/null 2>&1; then
          ${pkgs.iproute2}/bin/ip link add dev ${cfg.interface} type wireguard
        fi


        # Configure WireGuard private key
        ${pkgs.wireguard-tools}/bin/wg set ${cfg.interface} \
          private-key <(echo "$privateKey") \
          listen-port 0
        
        # Add peer
        ${pkgs.wireguard-tools}/bin/wg set ${cfg.interface} \
          peer $server_key \
          endpoint ''${wg_ip}:$server_port \
          allowed-ips 0.0.0.0/0,::/0 \
          persistent-keepalive 25
        
        # Assign IP address (use replace to handle re-runs)
        ${pkgs.iproute2}/bin/ip addr replace ''${peerip}/32 dev ${cfg.interface}
        
        # Bring up the interface
        ${pkgs.iproute2}/bin/ip link set up dev ${cfg.interface}

        ${pkgs.iproute2}/bin/ip route replace default dev ${cfg.interface} table 42

        ${cfg.postUp}
      '';

      preStop = ''
        echo Removing network interface ${cfg.interface}.

        ${cfg.preDown}

        ${pkgs.iproute2}/bin/ip link set down dev ${cfg.interface} 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link delete dev ${cfg.interface} 2>/dev/null || true

        ${cfg.postDown}
      '';
    };

    systemd.services.pia-vpn-portforward = mkIf cfg.portForward.enable {
      description = "Configure port-forwarding for PIA connection ${cfg.interface}";
      path = with pkgs; [ curl jq ];
      after = [ "pia-vpn.service" ];
      bindsTo = [ "pia-vpn.service" ];
      wantedBy = [ "pia-vpn.service" ];

      serviceConfig = {
        Type = "notify";
        Restart = "always";
        CacheDirectory = "pia-vpn";
        StateDirectory = "pia-vpn";
      };

      script = ''
        if [ ! -f $STATE_DIRECTORY/region.json ]; then
          >&2 echo "Region information not found; is pia-vpn.service running?"
          exit 1
        fi
        wg_hostname="$(cat $STATE_DIRECTORY/region.json | jq -r '.servers.wg[0].cn')"

        if [ ! -f $STATE_DIRECTORY/wireguard.json ]; then
          >&2 echo "Connection information not found; is pia-vpn.service running?"
          exit 1
        fi
        gateway="$(cat $STATE_DIRECTORY/wireguard.json | jq -r '.server_ip')"

        if [ ! -f $STATE_DIRECTORY/token.json ]; then
          >&2 echo "Token not found; is pia-vpn.esrvice running?"
        fi
        token="$(cat $STATE_DIRECTORY/token.json | jq -r '.token')"

        echo Enabling port forwarding...
        pfconfig=
        cacheFile=$STATE_DIRECTORY/portforward.json

        if [ -f "$cacheFile" ]; then
          pfconfig=$(cat "$cacheFile")
          if [ "$(echo "pfconfig" | jq -r '.status')" != "OK" ]; then
            echo "Invalid cached port-forwarding configuration. Fetching new configuration."
            pfconfig=
          fi
        fi

        if [ -z "$pfconfig" ]; then
          echo "Fetching port forwarding configuration..."
          pfconfig="$(curl -s -m 5 \
            --interface ${cfg.interface} \
            --connect-to "$wg_hostname::$gateway:" \
            --cacert "${cfg.certificateFile}" \
            -G --data-urlencode "token=''${token}" \
            "https://''${wg_hostname}:19999/getSignature")"
          if [ "$(echo "$pfconfig" | jq -r '.status')" != "OK" ]; then
            >&2 echo "Port forwarding configuration does not contain an OK status. Stopping."
            exit 1
          fi
          echo "$pfconfig" > "$cacheFile"
        fi

        if [ -z "$pfconfig" ]; then
          >&2 echo "Did not obtain port forwarding configuration. Stopping."
          exit 1
        fi

        signature="$(echo "$pfconfig" | jq -r '.signature')"
        payload="$(echo "$pfconfig" | jq -r '.payload')"
        port="$(echo "$payload" | base64 -d | jq -r '.port')"
        expires="$(echo "$payload" | base64 -d | jq -r '.expires_at')"

        echo "Forwarded port $port. Forwarding will expire at $(date --date "$expires")."

        systemd-notify --ready
        sleep 10

        while true; do
          response="$(curl -s -G -m 5 \
            --interface ${cfg.interface} \
            --connect-to "$wg_hostname::$gateway:" \
            --cacert "${cfg.certificateFile}" \
            --data-urlencode "payload=''${payload}" \
            --data-urlencode "signature=''${signature}" \
            "https://''${wg_hostname}:19999/bindPort")"
          if [ "$(echo "$response" | jq -r '.status')" != "OK" ]; then
            >&2 echo "Failed to bind port. Stopping."
            exit 1
          fi
          echo "Bound port $port. Forwarding will expire at $(date --date="$expires")."
          ${cfg.portForward.script}
          sleep 900
        done
      '';
    };
  };
}
