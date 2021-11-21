#!/bin/bash

# remove wolfram
apt purge wolfram-engine -y

# remove libre suite
apt remove --purge libreoffice* -y

# remove all helper packages
apt clean && apt autoremove -y
