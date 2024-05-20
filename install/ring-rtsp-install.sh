#!/usr/bin/env bash

# Copyright (c) z1haze
# Authors: z1haze
# License: MIT
# https://github.com/z1haze/ring-rtsp/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y {curl,gpg,git,jq}
msg_ok "Installed Dependencies"


msg_info "Downloading Ring-RTSP"
RELEASE=$(curl -s https://api.github.com/repos/z1haze/ring-rtsp/releases/latest | jq -r '.tag_name')
if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
cd ~
mkdir -p /opt/ring-rtsp
wget -q https://github.com/z1haze/ring-rtsp/archive/refs/tags/${RELEASE}.tar.gz -O ring-rtsp.tar.gz
msg_ok "Downloaded Ring-RTSP"


msg_info "Unpacking Ring-RTSP"
tar -xzf ring-rtsp.tar.gz -C /opt/ring-rtsp --strip-components 1
cd /opt/ring-rtsp
msg_ok "Unpacked Ring-RTSP"

cp /opt/ring-rtsp/.env.example /opt/ring-rtsp/.env

# get ring token from user
msg_info "Enter your Ring token (See https://github.com/dgreif/ring/wiki/Refresh-Tokens)"
read -s -r RING_TOKEN
echo "RING_TOKEN=\"${RING_TOKEN}\"" >> /opt/ring-rtsp/.env
msg_ok "Applied Ring token to .env file"


msg_info "Installing Node.js"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

# install app dependencies
msg_info "Installing Node.js Dependencies"
npm install &>/dev/null
msg_ok "Installed Node.js Dependencies"

# build app
msg_info "Compiling Ring-RTSP"
npm run build &>/dev/null
msg_ok "Compiled Ring-RTSP"

# create service
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ring-rtsp.service
[Unit]
Description=Ring RTSP Service
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/ring-rtsp/dist/index.js
WorkingDirectory=/opt/ring-rtsp
User=root
Group=root
Restart=always
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
Type=simple

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Service"

msg_info "Enabling and starting the systemd service"
systemctl enable ring-rtsp > /dev/null 2>&1
systemctl start ring-rtsp > /dev/null 2>&1
msg_ok "Enabled and started the systemd service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"