# ZFS Replication Setup Checklist

This checklist helps you verify everything is configured correctly for ZFS snapshot replication from Kraken to a remote host.

## Pre-Deployment Checklist

### Source Host (Kraken)

- [ ] Verify snapshots are being created: `zfs list -t snapshot tank/services | head -5`
- [ ] Verify SSH access to remote host works: `ssh box@192.168.1.15 'echo "SSH works"'`
- [ ] Root user can access SSH key for remote: `sudo cat ~/.ssh/id_rsa | head -1`
- [ ] Remote host IP in `configuration.nix` is correct (currently: 192.168.1.15)
- [ ] All datasets in the replication list exist locally

### Remote Host (Backup Target)

- [ ] SSH is running and accessible from Kraken
- [ ] ZFS is installed: `which zfs`
- [ ] Box user exists and has passwordless sudo for zfs commands
- [ ] Can create datasets: `sudo zfs create tank/test && sudo zfs destroy tank/test`
- [ ] Parent datasets exist or can be created:
  - [ ] tank
  - [ ] tank/services
  - [ ] tank/shack
  - [ ] tank/shack/cloud

## Deployment Steps

### 1. Prepare Remote Host (if first time)

On the remote backup target:

```bash
# Ensure parent datasets exist
sudo zfs create -p tank/services
sudo zfs create -p tank/shack/cloud

# Verify the box user can receive snapshots
sudo zfs allow box receive tank
sudo zfs allow box create,mount tank/services
sudo zfs allow box create,mount tank/shack
```

Or add to NixOS config on remote:

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

### 2. Deploy Configuration on Kraken

```bash
cd /Users/garrett/Repos/nixconfig
make switch
```

Or rebuild manually:

```bash
sudo nixos-rebuild switch --flake .#Kraken -L
```

### 3. Verify Service is Running

```bash
# Check if timer is active
sudo systemctl status zfs-replication.timer

# Check service
sudo systemctl status zfs-replication.service

# View enabled services
sudo systemctl list-timers zfs-replication*
```

### 4. Test Manual Replication

```bash
# Run replication manually
sudo systemctl start zfs-replication.service

# Monitor the job
sudo journalctl -u zfs-replication.service -f

# Or check the log file
sudo tail -f /var/log/zfs-replication.log
```

### 5. Verify On Remote Host

```bash
# Check replicated datasets
ssh box@192.168.1.15 'zfs list tank'
ssh box@192.168.1.15 'zfs list -t snapshot tank/services | head -5'
```

## Daily Operations

### Monitoring

```bash
# Check last replication
sudo journalctl -u zfs-replication.service --since "1 day ago"

# Monitor log file
sudo tail -50 /var/log/zfs-replication.log

# Check timer schedule
sudo systemctl list-timers zfs-replication.timer
```

### Manual Replication Trigger

```bash
# Force immediate replication
sudo systemctl start zfs-replication.service

# Watch progress
sudo journalctl -u zfs-replication.service -f
```

### Troubleshooting Commands

```bash
# Test SSH connectivity
ssh -v box@192.168.1.15 'zfs list'

# Check local snapshots
zfs list -t snapshot tank/services -H

# Check remote snapshots
ssh box@192.168.1.15 'zfs list -t snapshot tank/services -H'

# Check disk space on remote
ssh box@192.168.1.15 'zfs list tank'

# View replication errors
sudo journalctl -u zfs-replication.service -p err

# Manually send a snapshot for testing
sudo zfs send tank/services@test-snapshot | ssh box@192.168.1.15 'sudo zfs receive -F tank/services-test'
```

## Rollback & Recovery

### If Replication Needs to Start Over

```bash
# On remote host, remove the replicated dataset
ssh box@192.168.1.15 'sudo zfs destroy -r tank/services'

# Next replication run will do a full resync
sudo systemctl start zfs-replication.service
```

### Restore from Backup

```bash
# List available snapshots on remote
ssh box@192.168.1.15 'zfs list -t snapshot tank/services -r'

# Clone a snapshot for recovery
ssh box@192.168.1.15 'sudo zfs clone tank/services@snapshot-name tank/services-recovered'
```

## Performance Optimization

### Monitor Replication Progress

```bash
# During replication, monitor network usage
watch -n 1 'netstat -i'

# Monitor ZFS send/receive
sudo zfs list -H
ssh box@192.168.1.15 'zfs list -H'
```

### Adjust Schedule

To change replication time, edit in `/hosts/Kraken/configuration.nix`:

```nix
services.zfs-replication = {
  schedule = "02:00";  # Change this to new time
};
```

Then rebuild: `make switch`

## Common Issues & Solutions

### "SSH: Connection refused"
- [ ] Verify remote host is online: `ping 192.168.1.15`
- [ ] Verify SSH port is open: `ssh -p 22 box@192.168.1.15 'echo ok'`
- [ ] Check remote SSH config

### "zfs receive: incomplete stream"
- [ ] Check network stability during transfer
- [ ] Check local disk space: `zfs list`
- [ ] Try smaller snapshots first
- [ ] May need to restart replication

### "sudo: zfs receive: command not found"
- [ ] SSH to remote and verify: `which zfs`
- [ ] Check sudo config: `sudo -l` on remote
- [ ] Ensure correct path in sudo rules

### "Replication takes too long"
- [ ] Check network speed: `iperf3` or `scp` test
- [ ] Run during off-peak hours (currently 4 AM)
- [ ] Consider enabling compression (future enhancement)
- [ ] Check if incremental sync is working

## After Successful Setup

- [ ] Note backup schedule in documentation
- [ ] Add monitoring alerts if available
- [ ] Test disaster recovery procedures
- [ ] Schedule regular verification backups
- [ ] Document any custom changes to the module

## Support & Troubleshooting

For detailed information, see: `docs/ZFS_REPLICATION.md`

Module location: `modules/services/zfs-replication.nix`
Configuration: `hosts/Kraken/configuration.nix` (services.zfs-replication section)
