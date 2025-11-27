# ZFS Replication Architecture

## Daily Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      KRAKEN (Source)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  3:00 AM ► ZFS Auto-Snapshot Service (zfs.autoSnapshot)         │
│           Creates daily snapshots with timestamp                 │
│           ├─ tank/services@daily-2025-11-26                     │
│           ├─ tank/shack/cloud/immich@daily-2025-11-26           │
│           ├─ tank/shack/cloud/nextcloud@daily-2025-11-26        │
│           ├─ tank/shack/cloud/syncthing@daily-2025-11-26        │
│           └─ tank/shack/cloud/vaultwarden@daily-2025-11-26      │
│                                                                  │
│           Snapshots held for 30 days (auto-cleanup)             │
│                                                                  │
│  4:00 AM ► ZFS Replication Timer fires                          │
│           (systemd.timers.zfs-replication)                      │
│           └─ Triggers: zfs-replication.service                  │
│                                                                  │
│         ┌─────────────────────────────────┐                     │
│         │ Replication Script               │                     │
│         ├─────────────────────────────────┤                     │
│         │ ✓ Find latest snapshot          │                     │
│         │ ✓ Check remote dataset exists   │                     │
│         │ ✓ Create parent datasets (ssh)  │                     │
│         │ ✓ Send snapshot                 │                     │
│         │   ├─ Full: zfs send -R          │                     │
│         │   └─ Incremental: zfs send -i   │                     │
│         │ ✓ Receive on remote (ssh+sudo)  │                     │
│         │ ✓ Log results                   │                     │
│         └─────────────────────────────────┘                     │
│                     │                                            │
│                     ▼                                            │
│           /var/log/zfs-replication.log                          │
│           (rotated daily, kept 14 days)                         │
│                                                                  │
│           systemd journal                                        │
│           (journalctl -u zfs-replication.service)               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                          │
                    SSH Connection
                   (box user auth)
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│               REMOTE BACKUP HOST (192.168.1.15)                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  tank/services (replicated)                                     │
│  ├─ @daily-2025-11-25                                           │
│  ├─ @daily-2025-11-26  ◄── Latest snapshot                      │
│  └─ [other snapshots...]                                        │
│                                                                  │
│  tank/shack/cloud/immich (replicated)                           │
│  ├─ @daily-2025-11-25                                           │
│  ├─ @daily-2025-11-26  ◄── Latest snapshot                      │
│  └─ [other snapshots...]                                        │
│                                                                  │
│  tank/shack/cloud/nextcloud (replicated)                        │
│  tank/shack/cloud/syncthing (replicated)                        │
│  tank/shack/cloud/vaultwarden (replicated)                      │
│                                                                  │
│  ✓ All ready for disaster recovery                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Interaction

```
┌──────────────────────────────────────────────────────────────────┐
│                    KRAKEN (Kraken)                               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ ZFS Snapshots (Already Enabled)                            │  │
│  │ • Created daily at 3:00 AM                                 │  │
│  │ • Kept for 30 days                                         │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ ZFS Replication Module                                     │  │
│  │ (modules/services/zfs-replication.nix)                     │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │ Configuration Options:                                      │  │
│  │ • remoteHost: 192.168.1.15                                │  │
│  │ • remoteUser: box                                          │  │
│  │ • datasets: [5 cloud datasets]                             │  │
│  │ • schedule: 04:00 daily                                    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Systemd Timer                                              │  │
│  │ (systemd.timers.zfs-replication)                           │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │ • Runs daily at 4:00 AM ± 5 minutes                        │  │
│  │ • Persistent (catches missed runs)                         │  │
│  │ • Triggers: zfs-replication.service                        │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Systemd Service                                            │  │
│  │ (systemd.services.zfs-replication)                         │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │ • Type: oneshot                                            │  │
│  │ • Runs as: root                                            │  │
│  │ • Executes: /etc/zfs-replication/replicate.sh              │  │
│  │ • Restart on failure (3 attempts/hour)                    │  │
│  │ • Output: systemd journal + log file                       │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Replication Script                                         │  │
│  │ (/etc/zfs-replication/replicate.sh)                        │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │ For each dataset:                                          │  │
│  │  1. Get latest snapshot (zfs list)                        │  │
│  │  2. Check remote dataset (ssh)                            │  │
│  │  3. Create parent datasets if needed (ssh)                │  │
│  │  4. Find common snapshot for incremental sync              │  │
│  │  5. Send snapshot (zfs send → ssh → sudo zfs receive)      │  │
│  │  6. Log success/failure                                    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Logging                                                    │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │ • File: /var/log/zfs-replication.log                      │  │
│  │ • Rotated: Daily                                           │  │
│  │ • Kept: 14 days                                            │  │
│  │ • Journal: journalctl -u zfs-replication.service           │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## SSH Communication Flow

```
┌─────────────────┐
│  Kraken         │
│  (zfs-rep.sh)   │
└────────┬────────┘
         │
         │ SSH Key Auth
         │ (box user)
         │
         ▼
┌─────────────────────────────────────┐
│ Remote Host (192.168.1.15)          │
│ SSH Server (port 22)                │
└────────┬────────────────────────────┘
         │
         ├─► zfs list (check datasets)
         │
         ├─► zfs create -p (parent datasets)
         │
         └─► sudo zfs receive -Fu (receive stream)
             ▼
         ZFS Tank Pool
         (replicated data)
```

## Snapshot Transfer Flow

### First Time (Full Send)

```
Source Dataset        Send Stream           Remote Dataset
      │                  │                        │
 tank/services      ┌─────────────┐      tank/services
      │             │ zfs send -R │      (created)
      │             │ (all data)  │             │
      │             │ (~GB)       │             │
      │─────────────┤             ├─────────────│
      │             │  (over SSH) │             │
      │             │             │             │
      └─────────────►             ◄─────────────┘
                     │             │
                   zfs receive
                    (restore)
```

### Subsequent Times (Incremental Send)

```
Source Snapshots              Send Stream              Remote Snapshots
                              
daily-2025-11-24 ─────┐
daily-2025-11-25 ─────┤
daily-2025-11-26 ─────┤    ┌─────────────┐    ─────→ daily-2025-11-24
                       └────│ zfs send -i │────       daily-2025-11-25
                            │ (@daily-   │    ─────→ daily-2025-11-26
                            │  11-25...  │           (new)
                            │ @daily-    │    
                            │ 11-26)     │           
                            │ (~MB)      │           
                            └─────────────┘           
                          (delta only)
                          
Much faster & less bandwidth!
```

## Configuration Hierarchy

```
hosts/Kraken/configuration.nix
├─ imports: services-zfs-replication
│
└─ services.zfs-replication
   ├─ enable: true
   ├─ remoteHost: "192.168.1.15"
   ├─ remoteUser: "box"
   ├─ remotePool: "tank"
   ├─ schedule: "04:00"
   ├─ user: "root"
   │
   └─ datasets: [
      ├─ "tank/services"
      ├─ "tank/shack/cloud/immich"
      ├─ "tank/shack/cloud/nextcloud"
      ├─ "tank/shack/cloud/syncthing"
      └─ "tank/shack/cloud/vaultwarden"
     ]
        │
        ▼
modules/services/zfs-replication.nix
├─ NixOS module definition
├─ Environment config (replicate.sh script)
├─ Systemd service definition
├─ Systemd timer definition
└─ Logrotate configuration
```

## State Transitions

```
                        ┌──────────────┐
                        │ No Snapshots │
                        │ On Remote    │
                        └──────┬───────┘
                               │
                               ▼
        ┌──────────────────────────────────────┐
        │ First Replication (Full Send)        │
        │ zfs send -R <latest_snapshot>        │
        │ ~GB of data                          │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │ Replicated Dataset Exists            │
        │ with Common Snapshot                 │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │ Daily Incremental Replication        │
        │ zfs send -i @base @latest           │
        │ ~MB of data (delta only)            │
        └──────────────────────────────────────┘
```

## Error Handling

```
Replication Attempt
       │
       ▼
SSH Connection Failed?
       ├─ Yes ─► Log error ─► Retry in 5 min
       │                 (max 3 times/hour)
       │
       └─ No
           │
           ▼
    ZFS Command Failed?
           ├─ Yes ─► Log error ─► Retry in 5 min
           │                 (max 3 times/hour)
           │
           └─ No
               │
               ▼
        Success ─► Log to file & journal
                  Next run: tomorrow 4 AM
```

## Performance Profile

```
Dataset Size        First Sync      Daily Sync
─────────────────────────────────────────────────
100 MB              ~10 seconds     <1 second
1 GB                ~1-2 minutes    ~5 seconds
10 GB               ~10-20 min      ~30-60 sec
100 GB              ~2-4 hours      ~5-10 min

(Depends on network speed, storage I/O)

Incremental syncs are typically 100-1000x faster
than full syncs for stable data!
```
