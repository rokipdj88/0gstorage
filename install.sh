#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Banner
clear
echo -e '\e[34m'
echo -e '$$\   $$\ $$$$$$$$\      $$$$$$$$\           $$\                                       $$\     '
echo -e '$$$\  $$ |\__$$  __|     $$  _____|          $$ |                                      $$ |    '
echo -e '$$$$\ $$ |   $$ |        $$ |      $$\   $$\ $$$$$$$\   $$$$$$\  $$\   $$\  $$$$$$$\ $$$$$$\   '
echo -e '$$ $$\$$ |   $$ |$$$$$$\ $$$$$\    \$$\ $$  |$$  __$$\  \____$$\ $$ |  $$ |$$  _____|\_$$  _|  '
echo -e '$$ \$$$$ |   $$ |\______|$$  __|    \$$$$  / $$ |  $$ | $$$$$$$ |$$ |  $$ |\$$$$$$\    $$ |    '
echo -e '$$ |\$$$ |   $$ |        $$ |       $$  $$<  $$ |  $$ |$$  __$$ |$$ |  $$ | \____$$\   $$ |$$\ '
echo -e '$$ | \$$ |   $$ |        $$$$$$$$\ $$  /\$$\ $$ |  $$ |\$$$$$$$ |\$$$$$$  |$$$$$$$  |  \$$$$  |'
echo -e '\__|  \__|   \__|        \________|\__/  \__|\__|  \__| \_______| \______/ \_______/    \____/ '
echo -e '\e[0m'
echo -e "Join our Telegram channel: https://t.me/NTExhaust"
sleep 5

# Install dependencies
echo -e "${CYAN}Updating system and installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y clang cmake build-essential openssl pkg-config libssl-dev jq screen

# Install Golang
cd $HOME
ver="1.22.0"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustc --version

# Clone repository
echo -e "${CYAN}Cloning 0g-storage-node repository...${NC}"
cd $HOME
rm -rf 0g-storage-node
git clone https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node
git checkout v0.8.4
git submodule update --init

# Build project
echo -e "${CYAN}Building the project...${NC}"
cargo build --release | tee build.log

# Download config file
wget -O $HOME/0g-storage-node/run/config-testnet-turbo.toml https://josephtran.co/config-testnet-turbo.toml

# Set private key
echo -e "${BLUE}Enter your private key: ${NC}" && read -s PRIVATE_KEY
sed -i 's|^\s*#\?\s*miner_key\s*=.*|miner_key = "'$PRIVATE_KEY'"|' $HOME/0g-storage-node/run/config-testnet-turbo.toml
echo -e "${GREEN}Private key has been successfully added to the config file.${NC}"

# Setup systemd service
echo -e "${CYAN}Setting up systemd service...${NC}"
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Start node service
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl restart zgs
sudo systemctl status zgs --no-pager

tail -f ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d) &

# Start monitoring script in a screen session
echo -e "${CYAN}Starting monitoring in a screen session...${NC}"
screen -dmS zgs_monitor bash -c '
while true; do
    response=$(curl -s -X POST http://localhost:5678 -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"method\":\"zgs_getStatus\",\"params\":[],\"id\":1}")
    logSyncHeight=$(echo $response | jq '.result.logSyncHeight')
    connectedPeers=$(echo $response | jq '.result.connectedPeers')
    echo -e "logSyncHeight: \033[32m$logSyncHeight\033[0m, connectedPeers: \033[34m$connectedPeers\033[0m"
    sleep 5
done'

echo -e "${GREEN}Installation complete! Monitoring is running in a screen session (zgs_monitor). Use 'screen -r zgs_monitor' to view it.${NC}"
