{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.zfs-replication;
in
{
  options.services.zfs-replication = {
    enable = mkEnableOption "ZFS snapshot replication service";
    
    remoteUser = mkOption {
      type = types.str;
      default = "box";
      description = "Remote user for SSH connections";
    };
    
    remoteHost = mkOption {
      type = types.str;
      description = "Remote host IP or hostname for replication";
    };
    
    remotePool = mkOption {
      type = types.str;
      default = "tank";
      description = "Remote ZFS pool name";
    };
    
    datasets = mkOption {
      type = types.listOf types.str;
      default = [
        "tank/services"
        "tank/shack/cloud/immich"
        "tank/shack/cloud/nextcloud"
        "tank/shack/cloud/syncthing"
        "tank/shack/cloud/vaultwarden"
      ];
      description = "List of datasets to replicate";
    };
    
    schedule = mkOption {
      type = types.str;
      default = "02:00"; # 4 AM daily
      description = "Time to run replication (systemd timer format, HH:MM)";
    };
    
    user = mkOption {
      type = types.str;
      default = "root";
      description = "User to run the replication service as";
    };
  };
  
  config = mkIf cfg.enable {
    # Create the replication script
    environment.etc."zfs-replication/replicate.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # ZFS Dataset Replication Script
        # Replicates multiple ZFS datasets to a remote server
        
        set -euo pipefail
        
        # Logging
        log() {
          echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a /var/log/zfs-replication.log
        }
        
        # Configuration
        REMOTE_USER="${cfg.remoteUser}"
        REMOTE_HOST="${cfg.remoteHost}"
        REMOTE_POOL="${cfg.remotePool}"
        
        # Datasets to replicate
        DATASETS=(
          ${concatMapStringsSep "\n  " (d: "\"${d}\"") cfg.datasets}
        )
        
        log "Starting ZFS dataset replication to ''${REMOTE_USER}@''${REMOTE_HOST}"
        log "=================================================="
        
        # Function to replicate a single dataset
        replicate_dataset() {
            local dataset=$1
            log "Replicating: $dataset"
            
            # Get the latest snapshot for this dataset
            local latest_snapshot=$(zfs list -H -t snapshot -r "$dataset" -o name -s creation 2>/dev/null | tail -1)
            
            if [ -z "$latest_snapshot" ]; then
                log "✗ No snapshots found for $dataset"
                return 1
            fi
            
            log "Found snapshot: $latest_snapshot"
            
            # Ensure parent datasets exist on remote
            local parent_dataset="''${dataset%/*}"
            while [ "$parent_dataset" != "tank" ] && [ -n "$parent_dataset" ]; do
                local remote_parent="''${REMOTE_POOL}/''${parent_dataset#tank/}"
                if ! ssh -o ConnectTimeout=10 "''${REMOTE_USER}@''${REMOTE_HOST}" "zfs list \"$remote_parent\" > /dev/null 2>&1"; then
                    log "Creating parent dataset on remote: $remote_parent"
                    ssh "''${REMOTE_USER}@''${REMOTE_HOST}" "zfs create -p \"$remote_parent\"" || true
                fi
                parent_dataset="''${parent_dataset%/*}"
            done
            
            log "Sending snapshot to remote server..."
            local remote_dataset="''${REMOTE_POOL}/''${dataset#tank/}"
            
            # Check if this is the first sync or an incremental one
            if ssh "''${REMOTE_USER}@''${REMOTE_HOST}" "zfs list \"$remote_dataset\" > /dev/null 2>&1"; then
                # Incremental sync: find the latest common snapshot
                log "Performing incremental sync for $dataset"
                local remote_snapshots=$(ssh "''${REMOTE_USER}@''${REMOTE_HOST}" "zfs list -H -t snapshot -r \"$remote_dataset\" -o name -s creation" 2>/dev/null | awk -F'@' '{print $NF}' | sort -u)
                local local_snapshots=$(zfs list -H -t snapshot -r "$dataset" -o name -s creation 2>/dev/null | awk -F'@' '{print $NF}' | sort -u)
                
                # Find the latest common snapshot
                local base_snapshot=""
                for snap in $remote_snapshots; do
                    if echo "$local_snapshots" | grep -q "^$snap$"; then
                        base_snapshot="$snap"
                    fi
                done
                
                if [ -n "$base_snapshot" ]; then
                    log "Found common snapshot: @$base_snapshot, performing incremental send"
                    zfs send -i "@$base_snapshot" "$latest_snapshot" | ssh "''${REMOTE_USER}@''${REMOTE_HOST}" "sudo zfs receive -Fu \"$remote_dataset\""
                else
                    log "No common snapshot found, performing full send"
                    zfs send -R "$latest_snapshot" | ssh "''${REMOTE_USER}@''${REMOTE_HOST}" "sudo zfs receive -Fu \"$remote_dataset\""
                fi
            else
                # First time sync: send full snapshot
                log "Performing full sync (first time) for $dataset"
                zfs send -R "$latest_snapshot" | ssh "''${REMOTE_USER}@''${REMOTE_HOST}" "sudo zfs receive -Fu \"$remote_dataset\""
            fi
            
            if [ $? -eq 0 ]; then
                log "✓ Successfully replicated $dataset"
                return 0
            else
                log "✗ Failed to replicate $dataset"
                return 1
            fi
        }
        
        # Replicate each dataset
        failed_datasets=()
        for dataset in "''${DATASETS[@]}"; do
            if ! replicate_dataset "$dataset"; then
                failed_datasets+=("$dataset")
            fi
        done
        
        log ""
        log "=================================================="
        log "Replication Summary"
        log "=================================================="
        
        if [ ''${#failed_datasets[@]} -eq 0 ]; then
            log "✓ All datasets replicated successfully!"
            exit 0
        else
            log "✗ The following datasets failed to replicate:"
            printf '%s\n' "''${failed_datasets[@]}" | while read line; do
                log "  - $line"
            done
            exit 1
        fi
      '';
    };
    
    # Create systemd service
    systemd.services.zfs-replication = {
      description = "ZFS Snapshot Replication Service";
      documentation = [ "man:zfs(8)" "man:ssh(1)" ];
      
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = "/etc/zfs-replication/replicate.sh";
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "zfs-replication";
        # Restart policy
        Restart = "on-failure";
        RestartSec = "300";
        StartLimitInterval = "3600";
        StartLimitBurst = "3";
      };
    };
    
    # Create systemd timer
    systemd.timers.zfs-replication = {
      description = "Daily ZFS Snapshot Replication Timer";
      documentation = [ "man:systemd.timer(5)" ];
      
      timerConfig = {
        Unit = "zfs-replication.service";
        # Run at the specified time daily
        OnCalendar = "*-*-* ${cfg.schedule}:00";
        # Run immediately if the system was down at the scheduled time
        Persistent = true;
        # Add some randomness to prevent thundering herd
        RandomizedDelaySec = "5min";
      };
      
      wantedBy = [ "timers.target" ];
    };
    
    # Ensure log rotation
    services.logrotate.settings.zfs-replication = {
      files = "/var/log/zfs-replication.log";
      frequency = "daily";
      rotate = 14;
      missingok = true;
      notifempty = true;
      compress = true;
      delaycompress = true;
    };
  };
}
