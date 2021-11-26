#!/bin/bash

# used to calculate the space reclaimed at the end of the script
storage_before=`df -m --output=avail --total | awk 'END {print $1}'`

# remove wolfram
apt purge wolfram-engine -y

# remove libre suite
apt remove --purge libreoffice* -y

# remove all helper packages
apt clean && apt autoremove -y

storage_after=`df -m --output=avail --total | awk 'END {print $1}'`
storage_difference=$(( storage_after - storage_before ))

echo "remove-bloat.sh freed up $storage_difference MB on your system!"
