#!/bin/bash

# steamcmd Base Installation Script
#
# Server Files: /mnt/server
# Image to install with is 'debian:buster-slim'


STEAMCMD_INSTALL_DIR="/mnt/server/steamcmd"
REPO_BASE_URL="https://github.com/FriendosClub/pterodactyl-eggs/raw/main/garrysmod-advanced/src/garrysmod/"


apt -y update
apt -y --no-install-recommends install curl lib32gcc1 ca-certificates


## just in case someone removed the defaults.
if [ "${STEAM_USER}" == "" ]; then
    echo "No username set for steamcmd -- using anonymous account"

    STEAM_USER="anonymous"
    unset STEAM_PASS
    unset STEAM_AUTH
else
    echo "steamcmd user set to ${STEAM_USER}"
fi


## download and install steamcmd
cd /tmp
mkdir -p "$STEAMCMD_INSTALL_DIR"
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C "$STEAMCMD_INSTALL_DIR"
cd "$STEAMCMD_INSTALL_DIR"

# SteamCMD fails otherwise for some reason, even running as root.
# This is changed at the end of the install process anyways.
chown -R root:root /mnt
export HOME=/mnt/server


## install garry's mod using steamcmd
./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
    $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) \
    +force_install_dir /mnt/server \
    +app_update ${SRCDS_APPID} ${EXTRA_FLAGS} validate +quit
    ## other flags may be needed depending on install. looking at you cs 1.6


## set up 32 bit libraries
mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so


## set up 64 bit libraries
mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so


## (DEPRECATED -- SEE BELOW) download TF2 and CSS content
# ./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +force_install_dir /mnt/server/css/ +app_update 232330 validate +quit
# ./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +force_install_dir /mnt/server/tf2/ +app_update 232250 validate +quit

## Instead of duplicating CS:S etc installations, use mounts:
##   https://pterodox.com/guides/mounts.html#panel-configuration


## Fetch default configuration files from this repo
## TODO: Set variables after initial git push

# Install default lua files
curl -sSL "$REPO_BASE_URL/lua/autorun/server/workshop.lua" \
    -o /mnt/server/garrysmod/lua/autorun/server/workshop.lua

# Install default config files
declare -a DEFAULT_CONFIG_FILES=(
    "server.cfg"
    "gamemode_darkrp.cfg"
    "gamemode_sandbox.cfg"
    "gamemode_terrortown.cfg"
)

for CFG_FILE in "${DEFAULT_CONFIG_FILES[@]}"; do
    curl -sSL "$REPO_BASE_URL/cfg/$CFG_FILE" \
        -o "/mnt/server/garrysmod/cfg/$CFG_FILE"
done
