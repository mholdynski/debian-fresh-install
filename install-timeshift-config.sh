#!/bin/bash
set -euo pipefail

echo "Wykrywanie partycji BTRFS z systemem..."
BTRFS_DEV=$(findmnt -no SOURCE /  | sed "s/\[.*//")
UUID=$(blkid -s UUID -o value "$BTRFS_DEV")

if [ -z "$UUID" ]; then
    echo "Nie znaleziono UUID dla $BTRFS_DEV"
    exit 1
fi

echo "Wykryty dysk: $BTRFS_DEV"
echo "UUID: $UUID"

SNAP_PATH="/.snapshots"

# =============================
# 1. Config: system bez /home /.snapshots /var/log /var/cache (z harmonogramem)
# =============================
cat >/tmp/timeshift-system.json <<EOF
{
    "backup_device_uuid": "$UUID",
    "parent_device_uuid": "",
    "snapshot_path": "$SNAP_PATH",
    "do_first_run": "false",
    "btrfs_mode": "true",
    "include_btrfs_home": "false",
    "schedule_monthly": "false",
    "schedule_weekly": "true",
    "schedule_daily": "false",
    "schedule_hourly": "false",
    "schedule_boot": "false",
    "count_monthly": "2",
    "count_weekly": "7",
    "count_daily": "5",
    "count_hourly": "6",
    "count_boot": "5",
    "exclude": [
        "/home",
        "/.snapshots",
        "/var/log",
        "/var/cache"
    ],
    "exclude-btrfs": [
        "@home",
        "@snapshots",
        "@log",
        "@cache"
    ]
}
EOF
sudo mv /tmp/timeshift-system.json /etc/timeshift/timeshift-system.json

# =============================
# 2. Config: tylko home (bez harmonogramu)
# =============================
cat >/tmp/timeshift-home.json <<EOF
{
    "backup_device_uuid": "$UUID",
    "parent_device_uuid": "",
    "snapshot_path": "$SNAP_PATH",
    "do_first_run": "false",
    "btrfs_mode": "true",
    "include_btrfs_home": "true",
    "schedule_monthly": "false",
    "schedule_weekly": "false",
    "schedule_daily": "false",
    "schedule_hourly": "false",
    "schedule_boot": "false",
    "count_monthly": "2",
    "count_weekly": "3",
    "count_daily": "5",
    "count_hourly": "6",
    "count_boot": "5",
    "exclude": [
        "/",
        "/*",
        "!/home"
    ],
    "exclude-btrfs": [
        "@",
        "@log",
        "@cache",
        "@snapshots"
    ]
}
EOF
sudo mv /tmp/timeshift-home.json /etc/timeshift/timeshift-home.json

# =============================
# 3. Skrypt backup-system.sh
# =============================
cat >/tmp/backup-system.sh <<'EOF'
#!/bin/bash
NOW=$(date +"%Y-%m-%d_%H-%M")
USER_DESC="${1:-}"
if [ -n "$USER_DESC" ]; then
    DESC="System backup – $USER_DESC"
else
    DESC="System backup – $NOW"
fi
sudo cp /etc/timeshift/timeshift-system.json /etc/timeshift/timeshift.json
sudo timeshift --create --comments "$DESC"
EOF
sudo mv /tmp/backup-system.sh /usr/local/bin/backup-system.sh
sudo chmod +x /usr/local/bin/backup-system.sh

# =============================
# 4. Skrypt backup-home.sh
# =============================
cat >/tmp/backup-home.sh <<'EOF'
#!/bin/bash
NOW=$(date +"%Y-%m-%d_%H-%M")
USER_DESC="${1:-}"
if [ -n "$USER_DESC" ]; then
    DESC="Home backup – $USER_DESC"
else
    DESC="Home backup – $NOW"
fi
sudo cp /etc/timeshift/timeshift-home.json /etc/timeshift/timeshift.json
sudo timeshift --create --comments "$DESC"
sudo cp /etc/timeshift/timeshift-system.json /etc/timeshift/timeshift.json
EOF
sudo mv /tmp/backup-home.sh /usr/local/bin/backup-home.sh
sudo chmod +x /usr/local/bin/backup-home.sh

# =============================
# 5. Alias do .bashrc
# =============================
grep -qxF "alias bsys='backup-system.sh'" ~/.bashrc || echo "alias bsys='backup-system.sh'" >> ~/.bashrc
grep -qxF "alias bhome='backup-home.sh'" ~/.bashrc || echo "alias bhome='backup-home.sh'" >> ~/.bashrc

echo "Instalacja zakończona!"
echo "Załaduj aliasy: source ~/.bashrc"
echo "Użycie:"
echo "    bsys 'opis backupu systemu'"
echo "    bhome 'opis backupu home'"
echo ""
echo "Harmonogram: Timeshift co tydzień zrobi snapshot systemu (bez /home) i utrzyma max 7 tygodniowych."
