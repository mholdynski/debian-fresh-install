#!/bin/bash
set -euo pipefail

echo "Tworzenie katalogów dla snapshotów..."
sudo mkdir -p /.snapshots/system
sudo mkdir -p /.snapshots/home
sudo chown root:root /.snapshots/system /.snapshots/home
sudo chmod 755 /.snapshots/system /.snapshots/home

# =============================
# 1. Konfiguracja Snapper – system
# =============================
sudo snapper -c system create-config /
sudo sed -i 's|^TIMELINE_CREATE="yes"|TIMELINE_CREATE="yes"|' /etc/snapper/configs/system
sudo sed -i 's|^TIMELINE_CLEANUP="yes"|TIMELINE_CLEANUP="yes"|' /etc/snapper/configs/system
sudo sed -i 's|^TIMELINE_LIMIT_WEEKLY="0"|TIMELINE_LIMIT_WEEKLY="7"|' /etc/snapper/configs/system
sudo sed -i 's|^TIMELINE_LIMIT_MONTHLY="0"|TIMELINE_LIMIT_MONTHLY="2"|' /etc/snapper/configs/system
sudo sed -i 's|^NUMBER_CLEANUP="yes"|NUMBER_CLEANUP="no"|' /etc/snapper/configs/system
sudo sed -i 's|^SNAPSHOT_DIRECTORY=""|SNAPSHOT_DIRECTORY="/.snapshots/system"|' /etc/snapper/configs/system

# =============================
# 2. Konfiguracja Snapper – home
# =============================
sudo snapper -c home create-config /home
sudo sed -i 's|^TIMELINE_CREATE="yes"|TIMELINE_CREATE="no"|' /etc/snapper/configs/home
sudo sed -i 's|^TIMELINE_CLEANUP="yes"|TIMELINE_CLEANUP="no"|' /etc/snapper/configs/home
sudo sed -i 's|^NUMBER_CLEANUP="yes"|NUMBER_CLEANUP="no"|' /etc/snapper/configs/home
sudo sed -i 's|^SNAPSHOT_DIRECTORY=""|SNAPSHOT_DIRECTORY="/.snapshots/home"|' /etc/snapper/configs/home

# =============================
# 3. Skrypty tworzenia snapshotów ręcznie
# =============================
cat >/tmp/snap-system.sh <<'EOF'
#!/bin/bash
NOW=$(date +"%Y-%m-%d_%H-%M")
USER_DESC="${1:-}"
if [ -n "$USER_DESC" ]; then
    DESC="System snapshot – $USER_DESC"
else
    DESC="System snapshot – $NOW"
fi
sudo snapper -c system create --description "$DESC"
EOF
sudo mv /tmp/snap-system.sh /usr/local/bin/snap-system.sh
sudo chmod +x /usr/local/bin/snap-system.sh

cat >/tmp/snap-home.sh <<'EOF'
#!/bin/bash
NOW=$(date +"%Y-%m-%d_%H-%M")
USER_DESC="${1:-}"
if [ -n "$USER_DESC" ]; then
    DESC="Home snapshot – $USER_DESC"
else
    DESC="Home snapshot – $NOW"
fi
sudo snapper -c home create --description "$DESC"
EOF
sudo mv /tmp/snap-home.sh /usr/local/bin/snap-home.sh
sudo chmod +x /usr/local/bin/snap-home.sh

# =============================
# 4. Alias do .bashrc
# =============================
grep -qxF "alias ssys='snap-system.sh'" ~/.bashrc || echo "alias ssys='snap-system.sh'" >> ~/.bashrc
grep -qxF "alias shome='snap-home.sh'" ~/.bashrc || echo "alias shome='snap-home.sh'" >> ~/.bashrc

echo "Instalacja zakończona!"
echo "Załaduj aliasy: source ~/.bashrc"
echo "Użycie:"
echo "    ssys 'opis snapshotu systemu'"
echo "    shome 'opis snapshotu home'"
echo ""
echo "Snapper zrobi automatyczne cotygodniowe snapshoty systemu, ręczne snapshoty będą w /.snapshots i nie będą kasowane automatycznie."
