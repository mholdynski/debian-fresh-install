#!/bin/bash
set -euo pipefail

echo "🔍 Wykrywanie partycji BTRFS z systemem..."
BTRFS_DEV=$(findmnt -no SOURCE /)
UUID=$(blkid -s UUID -o value "$BTRFS_DEV")

if [ -z "$UUID" ]; then
    echo "❌ Nie znaleziono UUID dla $BTRFS_DEV"
    exit 1
fi

echo "✅ Wykryty dysk: $BTRFS_DEV"
echo "✅ UUID: $UUID"

# =============================
# 1. Config: system bez /home (z harmonogramem)
# =============================
cat >/tmp/timeshift-system.json <<EOF
{
    "backup_device_uuid": "$UUID",
    "parent_device_uuid": "",
    "do_first_run": "false",
    "btrfs_mode": "true",
    "include_btrfs_home": "false",
    "snapshot_type": "ONDEMAND",
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
    "count_on_demand": "5",
    "exclude": [
        "/home"
    ],
    "exclude-btrfs": [
        "@home"
    ]
}
EOF
sudo mv /tmp/timeshift-system.json /etc/timeshift-system.json

# =============================
# 2. Config: tylko home (bez harmonogramu)
# =============================
cat >/tmp/timeshift-home.json <<EOF
{
    "backup_device_uuid": "$UUID",
    "parent_device_uuid": "",
    "do_first_run": "false",
    "btrfs_mode": "true",
    "include_btrfs_home": "true",
    "snapshot_type": "ONDEMAND",
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
    "count_on_demand": "5",
    "exclude": [
        "/",
        "/*",
        "!/home"
    ],
    "exclude-btrfs": [
        "@"
    ]
}
EOF
sudo mv /tmp/timeshift-home.json /etc/timeshift-home.json

# =============================
# 3. Skrypt backup-system.sh
# =============================
cat >/tmp/backup-system.sh <<'EOF'
#!/bin/bash
DESC="$1"
sudo cp /etc/timeshift-system.json /etc/timeshift.json
sudo timeshift --create --comments "${DESC:-System backup (bez /home)}"
sudo cp /etc/timeshift-system.json /etc/timeshift.json
EOF
sudo mv /tmp/backup-system.sh /usr/local/bin/backup-system.sh
sudo chmod +x /usr/local/bin/backup-system.sh

# =============================
# 4. Skrypt backup-home.sh
# =============================
cat >/tmp/backup-home.sh <<'EOF'
#!/bin/bash
DESC="$1"
sudo cp /etc/timeshift-home.json /etc/timeshift.json
sudo timeshift --create --comments "${DESC:-Home backup}"
sudo cp /etc/timeshift-system.json /etc/timeshift.json
EOF
sudo mv /tmp/backup-home.sh /usr/local/bin/backup-home.sh
sudo chmod +x /usr/local/bin/backup-home.sh

# =============================
# 5. Alias do .bashrc
# =============================
if ! grep -q "alias bsys=" ~/.bashrc; then
    echo "alias bsys='backup-system.sh'" >> ~/.bashrc
fi
if ! grep -q "alias bhome=" ~/.bashrc; then
    echo "alias bhome='backup-home.sh'" >> ~/.bashrc
fi

echo "✅ Instalacja zakończona!"
echo "ℹ️ Załaduj aliasy: source ~/.bashrc"
echo "📦 Użycie:"
echo "    bsys 'opis backupu systemu'"
echo "    bhome 'opis backupu home'"
echo ""
echo "📅 Harmonogram: Timeshift co tydzień zrobi snapshot systemu (bez /home) i utrzyma max 7 tygodniowych."
