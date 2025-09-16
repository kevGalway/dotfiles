Per‑machine config

Overview
- Put machine‑specific files under `machines/<HOSTNAME>` where `<HOSTNAME>` is the short hostname (`hostname -s`).
- For disk mounts, prefer systemd mount units for reliability and on‑demand mounting.

Systemd mounts
- Place `.mount` (and optional `.automount`) files in `machines/<HOSTNAME>/systemd`.
- Run `./scripts/35-systemd-mounts.sh` (or `./scripts/run-all.sh`) to install and enable them.
- Use device paths like `/dev/disk/by-uuid/<UUID>` in `What=`. Get UUIDs with: `sudo blkid`.

Example: `/mnt/data` on ext4 by UUID
1) Create files in `machines/EXAMPLE-HOST/systemd/`:
   - `mnt-data.mount`
   - `mnt-data.automount`
2) Copy that directory to `machines/<YOUR-HOSTNAME>/systemd` and edit `What=`.
3) Run the install script.

Notes
- `.automount` makes the mount happen on first access and avoids boot delays (`nofail` is still recommended).
- Ensure the mount point path in `Where=` exists; the script will create it if needed.
- For removable drives, consider also adding `x-systemd.idle-timeout=60` via `Options=` in the `.mount`.

