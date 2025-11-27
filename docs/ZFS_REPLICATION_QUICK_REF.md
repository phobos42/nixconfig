# ZFS Replication Quick Reference

## What's Happening?

Every day on Kraken:
- **3:00 AM**: Daily snapshots are created automatically
- **4:00 AM**: Snapshots are replicated to the remote backup host at `192.168.1.15`

## Quick Commands

### Check Status

```bash
# Is the timer running?
systemctl status zfs-replication.timer

# When will it run next?
systemctl list-timers zfs-replication.timer

# What happened last time?
journalctl -u zfs-replication.service --since "1 day ago"
```

### Run Now

```bash
# Start replication immediately
sudo systemctl start zfs-replication.service

# Watch it happen
sudo journalctl -u zfs-replication.service -f
```

### Check Logs

```bash
# Detailed log file
sudo tail -f /var/log/zfs-replication.log

# Or systemd journal
sudo journalctl -u zfs-replication.service -f
```

### View Snapshots

```bash
# Local snapshots (on Kraken)
zfs list -t snapshot tank/services | head -10

# Remote snapshots (on backup host)
ssh box@192.168.1.15 'zfs list -t snapshot tank/services | head -10'
```

## Datasets Being Replicated

- `tank/services`
- `tank/shack/cloud/immich`
- `tank/shack/cloud/nextcloud`
- `tank/shack/cloud/syncthing`
- `tank/shack/cloud/vaultwarden`

## Configuration File

`hosts/Kraken/configuration.nix` - search for `services.zfs-replication`

To change the schedule, backup host, or datasets:
1. Edit `hosts/Kraken/configuration.nix`
2. Run `make switch` to apply changes

## Troubleshooting

**Replication isn't running?**
```bash
sudo systemctl status zfs-replication.timer
sudo systemctl start zfs-replication.timer
```

**Last replication failed?**
```bash
journalctl -u zfs-replication.service -p err
```

**SSH connection issues?**
```bash
ssh -v box@192.168.1.15 'zfs list'
```

**No snapshots on remote?**
```bash
ssh box@192.168.1.15 'zfs list tank'
```

## Module Details

- **Service**: `zfs-replication.service` - Does the actual replication
- **Timer**: `zfs-replication.timer` - Schedules when the service runs
- **Module**: `modules/services/zfs-replication.nix` - Configuration code
- **Log file**: `/var/log/zfs-replication.log` - Detailed logs (rotated daily)

## More Information

- Full setup guide: `docs/ZFS_REPLICATION_SETUP.md`
- Detailed documentation: `docs/ZFS_REPLICATION.md`
