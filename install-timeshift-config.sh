#!/bin/bash
set -euo pipefail

sudo apt update
sudo apt install -y timeshift

echo "Wykrywanie partycji BTRFS z systemem..."
BTRFS_DEV=$(findmnt -no SOURCE /  | sed "s/\[.*//")
UUID=$(blkid -s UUID -o value "$BTRFS_DEV")

if [ -z "$UUID" ]; then
    echo "Nie znaleziono UUID dla $BTRFS_DEV"
    exit 1
fi

echo "Wykryty dysk: $BTRFS_DEV"
echo "UUID: $UUID"

# =============================
# Config: system bez /home /var/log /var/cache /var/tmp (z harmonogramem)
# =============================
cat >/tmp/timeshift-system.json <<EOF
{
    "backup_device_uuid": "$UUID",
    "parent_device_uuid": "",
    "do_first_run": "false",
    "btrfs_mode": "true",
    "include_btrfs_home": "false",
    "stop_cron_emails" : "true",
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
    "snapshot_size" : "0",
    "snapshot_count" : "0",
    "exclude": [
        "/home",
        "/var/tmp",
        "/var/log",
        "/var/cache"
    ],
    "exclude-apps": [
    ]
}
EOF
sudo mv /etc/timeshift/timeshift.json /etc/timeshift/timeshift.json.bak
sudo mv /tmp/timeshift-system.json /etc/timeshift/timeshift.json

# =============================
# Skrypt backup-system.sh
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
sudo timeshift --create --comments "$DESC"
EOF
sudo mv /tmp/backup-system.sh /usr/local/bin/backup-system.sh
sudo chmod +x /usr/local/bin/backup-system.sh

# =============================
# Alias do .bashrc
# =============================
grep -qxF "alias backup-sys='backup-system.sh'" ~/.bashrc || echo "alias backup-sys='backup-system.sh'" >> ~/.bashrc

echo "Instalacja zakończona!"
echo "Załaduj alias: source ~/.bashrc"
echo "Użycie:"
echo "    backup-sys 'opis backupu systemu'"
echo "Harmonogram: Timeshift co tydzień zrobi snapshot systemu (bez /home) i utrzyma max 7 tygodniowych."
