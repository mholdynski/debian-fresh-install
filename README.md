Po instalacji:

chmod +x install-timeshift-config.sh  
./install-timeshift-config.sh  
source ~/.bashrc


/etc/snapper/configs/system
SUBVOLUME="/"  
FSTYPE="btrfs"  

# snapshoty będą widoczne w /.snapshots/system  
SNAPSHOT_DIRECTORY="/.snapshots/system"  

# Harmonogram cotygodniowy (snapper-cleanup.timer + snapper-timeline.timer)  
TIMELINE_CREATE="yes"  
TIMELINE_CLEANUP="yes"  
TIMELINE_MIN_AGE="1800"  
TIMELINE_LIMIT_HOURLY="0"  
TIMELINE_LIMIT_DAILY="0"  
TIMELINE_LIMIT_WEEKLY="7"  
TIMELINE_LIMIT_MONTHLY="2"  
TIMELINE_LIMIT_YEARLY="0"  

# Ręczne snapshoty – bez automatycznego czyszczenia  
NUMBER_CLEANUP="no"


/etc/snapper/configs/home  
SUBVOLUME="/home"  
FSTYPE="btrfs"  

# snapshoty będą widoczne w /.snapshots/home  
SNAPSHOT_DIRECTORY="/.snapshots/home"  

# Harmonogram wyłączony – tylko ręczne snapshoty  
TIMELINE_CREATE="no"  
TIMELINE_CLEANUP="no"  

# Żadnego auto-cleanup  
NUMBER_CLEANUP="no"
