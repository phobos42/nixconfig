# ZFS Snapshot Replication Setup

This guide explains how the ZFS snapshot replication system works on Kraken and how to manage it.

## Overview

The system consists of:

1. **Daily Snapshots**: Created automatically at **3:00 AM** by `services.zfs.autoSnapshot`
2. **Replication Service**: Syncs snapshots to a remote host at **4:00 AM** (1 hour after snapshots)
3. **Systemd Timer**: Automatically runs the replication on schedule

## How It Works

### Snapshots
- Snapshots are created daily via `services.zfs.autoSnapshot` at 3 AM
- Snapshots are kept for 30 days by default
- Snapshots are created for all configured datasets

### Replication
The replication service:
1. Finds the latest snapshot for each dataset
2. Checks if the dataset exists on the remote host
3. Creates parent datasets if needed
4. Performs **incremental** sync (if datasets already exist on remote)
5. Falls back to **full** sync on first replication
6. Logs all operations to `/var/log/zfs-replication.log`

## Configuration

The replication is configured in `/hosts/Kraken/configuration.nix`:

```nix
services.zfs-replication = {
  enable = true;
  remoteUser = "box";
  remoteHost = "192.168.1.15";     # Update with your remote host
  remotePool = "tank";
  datasets = [
    "tank/services"
    "tank/shack/cloud/immich"
    "tank/shack/cloud/nextcloud"
    "tank/shack/cloud/syncthing"
    "tank/shack/cloud/vaultwarden"
  ];
  schedule = "04:00";  # 4 AM daily
  user = "root";
};
```

### Configuration Options

- **remoteUser**: SSH user on remote host (default: `box`)
- **remoteHost**: Remote hostname or IP address
- **remotePool**: Pool name on remote (default: `tank`)
- **datasets**: List of datasets to replicate
- **schedule**: Time to run replication in HH:MM format (default: `04:00`)
- **user**: User to run replication as (default: `root`)

## Monitoring & Logs

View the replication logs:

```bash
# View recent logs
sudo tail -f /var/log/zfs-replication.log

# View systemd journal
journalctl -u zfs-replication.service -f

# View timer status
systemctl status zfs-replication.timer
```

## Manual Replication

To run replication manually:

```bash
sudo systemctl start zfs-replication.service
```

Check the status:

```bash
sudo systemctl status zfs-replication.service
journalctl -u zfs-replication.service -n 50
```

## Remote Host Requirements

The remote host must have:

1. **SSH access** from the source (Kraken) with key-based authentication
2. **ZFS** installed and configured
3. **Sudo** access for the `box` user to run `zfs receive` and `zfs create` commands

Example sudo configuration on remote:

```bash
# As root on remote host
cat >> /etc/sudoers.d/box <<EOF
box ALL=(ALL) NOPASSWD: /usr/sbin/zfs receive
box ALL=(ALL) NOPASSWD: /usr/sbin/zfs create
EOF
```

Or in NixOS:

```nix
security.sudo.extraRules = [{
  users = [ "box" ];
  commands = [
    {
      command = "/run/current-system/sw/bin/zfs receive";
      options = [ "NOPASSWD" ];
    }
    {
      command = "/run/current-system/sw/bin/zfs create";
      options = [ "NOPASSWD" ];
    }
  ];
}];
```

## Troubleshooting

### Service won't start
```bash
# Check for syntax errors in configuration
nixos-rebuild test

# View error details
journalctl -u zfs-replication.service -p err
```

### Replication hangs
- Check SSH connectivity: `ssh box@192.168.1.15 'zfs list'`
- Check network connectivity: `ping 192.168.1.15`
- Check SSH key configuration

### Incremental sync fails
- Verify snapshots exist on remote: `ssh box@192.168.1.15 'zfs list -t snapshot tank/services'`
- Check for mismatched snapshot names
- Manual full resync may be needed

## Disabling Replication

To temporarily disable replication:

```bash
# Stop the timer
sudo systemctl stop zfs-replication.timer
sudo systemctl disable zfs-replication.timer

# Then rebuild your system
make switch
```

## Logs Retention

Logs are automatically rotated daily and kept for 14 days. Configuration is in the NixOS module at:
`/modules/services/zfs-replication.nix`

## Performance Considerations

- Replication happens at 4 AM to minimize impact on daytime usage
- Add 5-minute random delay to prevent thundering herd
- Incremental snapshots are much faster than full syncs
- Network bandwidth determines transfer speed

## Future Enhancements

Possible improvements:
- Email notifications on failure
- Prometheus/Grafana monitoring metrics
- Compression during transfer
- Bandwidth limiting
- Automated recovery from failed syncs
