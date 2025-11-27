# ZFS Replication Implementation Summary

## What Was Implemented

A complete automated ZFS snapshot replication system for Kraken that:

1. **Creates daily snapshots** at 3:00 AM (already configured)
2. **Replicates snapshots** to a remote backup host at 4:00 AM
3. **Handles incremental syncs** for efficient bandwidth usage
4. **Automatically retries** failed replication jobs
5. **Logs all operations** with automatic rotation

## Files Created/Modified

### New Files Created:

1. **`modules/services/zfs-replication.nix`** - Main NixOS module
   - Configurable service for ZFS replication
   - Creates systemd service and timer
   - Includes comprehensive replication script
   - Handles log rotation

2. **`docs/ZFS_REPLICATION.md`** - Full documentation
   - Detailed explanation of how it works
   - Configuration options
   - Monitoring and logging
   - Troubleshooting guide

3. **`docs/ZFS_REPLICATION_SETUP.md`** - Setup checklist
   - Pre-deployment verification
   - Step-by-step deployment guide
   - Daily operations
   - Recovery procedures

4. **`docs/ZFS_REPLICATION_QUICK_REF.md`** - Quick reference
   - Common commands
   - Status checks
   - Basic troubleshooting

### Modified Files:

1. **`hosts/Kraken/configuration.nix`**
   - Added `services-zfs-replication` to imports
   - Added replication service configuration

## How It Works

### Daily Schedule

```
3:00 AM  → Snapshots created by zfs.autoSnapshot
4:00 AM  → Replication service starts (with 5-min random delay)
           ↓
           Finds latest snapshot for each dataset
           ↓
           Checks if dataset exists on remote
           ↓
           Incremental sync (if exists) or Full sync (first time)
           ↓
           Logs results to /var/log/zfs-replication.log
```

### Replication Strategy

- **First sync**: Full snapshot send using `zfs send -R`
- **Subsequent syncs**: Incremental using `zfs send -i` (much faster)
- **Failure handling**: Automatic retry after 5 minutes, max 3 attempts per hour
- **Parent datasets**: Created automatically on remote if needed

## Configuration

The service is configured in `hosts/Kraken/configuration.nix`:

```nix
services.zfs-replication = {
  enable = true;
  remoteUser = "box";
  remoteHost = "192.168.1.15";      # ← Update this!
  remotePool = "tank";
  datasets = [
    "tank/services"
    "tank/shack/cloud/immich"
    "tank/shack/cloud/nextcloud"
    "tank/shack/cloud/syncthing"
    "tank/shack/cloud/vaultwarden"
  ];
  schedule = "04:00";  # 4 AM
  user = "root";
};
```

**Important**: Update `remoteHost` to your actual backup target IP/hostname!

## Before Deploying

### On Remote Host (Backup Target)

Ensure it has:

1. **ZFS installed** and a `tank` pool
2. **SSH access** from Kraken (key-based auth)
3. **Sudo access** for the `box` user to run `zfs receive` and `zfs create`

Example NixOS sudo configuration:

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

## Deployment

1. **Update the remote host IP** in `hosts/Kraken/configuration.nix`
2. **Verify remote host prerequisites** (see checklist above)
3. **Deploy the configuration**:

```bash
cd /Users/garrett/Repos/nixconfig
make switch
```

Or manually:

```bash
sudo nixos-rebuild switch --flake .#Kraken -L
```

## Testing

After deployment:

```bash
# Check timer
sudo systemctl status zfs-replication.timer

# List next run time
sudo systemctl list-timers zfs-replication.timer

# Manual test
sudo systemctl start zfs-replication.service

# Watch progress
sudo journalctl -u zfs-replication.service -f

# View logs
sudo tail -f /var/log/zfs-replication.log
```

## Monitoring Commands

```bash
# See recent replication attempts
journalctl -u zfs-replication.service --since "1 day ago"

# Check for errors
journalctl -u zfs-replication.service -p err

# List snapshot on remote
ssh box@192.168.1.15 'zfs list -t snapshot tank/services'

# Check remote pool usage
ssh box@192.168.1.15 'zfs list tank'
```

## Key Features

✅ **Automated**: Runs daily on schedule  
✅ **Efficient**: Incremental snapshots save bandwidth  
✅ **Reliable**: Automatic retry on failure  
✅ **Observable**: Comprehensive logging to file and journal  
✅ **Recoverable**: Can be manually triggered anytime  
✅ **Configurable**: All options in NixOS config  
✅ **Rotated logs**: Keeps 14 days of logs  

## What Gets Replicated

- `tank/services`
- `tank/shack/cloud/immich`
- `tank/shack/cloud/nextcloud`
- `tank/shack/cloud/syncthing`
- `tank/shack/cloud/vaultwarden`

## Future Enhancements

Possible improvements:

- Email notifications on failure
- Prometheus metrics for monitoring
- Compression during transfer (`zfs send | gzip`)
- Bandwidth rate limiting
- Automatic cleanup of old snapshots on remote
- Pre-replication validation checks

## Support & Documentation

- **Quick reference**: `docs/ZFS_REPLICATION_QUICK_REF.md`
- **Full guide**: `docs/ZFS_REPLICATION.md`
- **Setup checklist**: `docs/ZFS_REPLICATION_SETUP.md`
- **Module code**: `modules/services/zfs-replication.nix`

## Next Steps

1. ✅ Review the implementation (done!)
2. ⬜ Update `remoteHost` IP if needed
3. ⬜ Prepare the remote backup host
4. ⬜ Deploy: `make switch`
5. ⬜ Test manual replication: `sudo systemctl start zfs-replication.service`
6. ⬜ Verify snapshots on remote: `ssh box@backup 'zfs list'`
7. ⬜ Monitor logs: `sudo tail -f /var/log/zfs-replication.log`
