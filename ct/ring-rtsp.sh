#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func -o -; curl -s https://raw.githubusercontent.com/z1haze/ring-rtsp/main/misc/build.func -o -)

# Copyright (c) z1haze
# Authors: z1haze
# License: MIT
# https://github.com/z1haze/ring-rtsp/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____  _                ____  ___________ ____
   / __ \(_)___  ____ _   / __ \/_  __/ ___// __ \
  / /_/ / / __ \/ __ `/  / /_/ / / /  \__ \/ /_/ /
 / _, _/ / / / / /_/ /  / _, _/ / /  ___/ / ____/
/_/ |_/_/_/ /_/\__, /  /_/ |_| /_/  /____/_/
              /____/

EOF
}
header_info
echo -e "Loading..."
APP="Ring-RTSP"
var_disk="2"
var_cpu="2"
var_ram="1024"
var_os="debian"
var_version="11"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="0"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
  if [[ ! -f /etc/systemd/system/ring.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  msg_error "There is currently no update path available."
  exit
}

start
build_container
description

msg_info "Setting Container to Normal Resources"
pct set $CTID -memory 1024
msg_ok "Set Container to Normal Resources"
msg_ok "Completed Successfully!\n"
echo -e "${APP} server is listening
         ${BL}rtsp://${IP}:8554${CL} \n"

echo -e "${APP} client is listening
         ${BL}rtsp://${IP}:554${CL} \n"