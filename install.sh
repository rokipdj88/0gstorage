#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

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

# Perbarui daftar paket
sudo apt-get update

# Instal paket yang diperlukan
sudo apt-get install -y clang cmake build-essential openssl pkg-config libssl-dev jq screen

# Tentukan versi Go yang ingin diinstal
ver="1.22.0"

# Pindah ke direktori home
cd "$HOME"

# Unduh file tar Go
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"

# Hapus instalasi Go sebelumnya (jika ada)
sudo rm -rf /usr/local/go

# Ekstrak file tar ke /usr/local
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"

# Hapus file tar setelah ekstraksi
rm "go$ver.linux-amd64.tar.gz"

# Tambahkan Go ke PATH jika belum ada
echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> ~/.bash_profile

# Muat ulang profil bash
. "$HOME/.bash_profile"

# Tampilkan versi Go
go version

# Instal Rust menggunakan rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Muat ulang konfigurasi shell
. "$HOME/.cargo/env"

# Tampilkan versi Rust
rustc --version

# Clone repository 0g-storage-node
cd "$HOME"
rm -rf 0g-storage-node
git clone https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node

git checkout v0.8.4

git submodule update --init

# Bangun proyek menggunakan cargo dengan nohup agar berjalan di latar belakang
nohup cargo build --release > build.log 2>&1 &

# Tunggu hingga proses build selesai
wait

# Unduh file konfigurasi setelah proses build selesai
wget -O "$HOME/0g-storage-node/run/config-testnet-turbo.toml" https://josephtran.co/config-testnet-turbo.toml

# Minta pengguna memasukkan private key secara aman
printf '\033[34mEnter your private key: \033[0m'
read -s PRIVATE_KEY

# Tambahkan private key ke dalam file konfigurasi
sed -i 's|^\s*#\?\s*miner_key\s*=.*|miner_key = "'"$PRIVATE_KEY"'"|' "$HOME/0g-storage-node/run/config-testnet-turbo.toml"

echo -e "\033[32mPrivate key has been successfully added to the config file.\033[0m"

# Tampilkan parameter penting dari file konfigurasi
grep -E "^(network_dir|network_enr_address|network_enr_tcp_port|network_enr_udp_port|network_libp2p_port|network_discovery_port|rpc_listen_address|rpc_enabled|db_dir|log_config_file|log_contract_address|mine_contract_address|reward_contract_address|log_sync_start_block_number|blockchain_rpc_endpoint|auto_sync_enabled|find_peer_timeout)" "$HOME/0g-storage-node/run/config-testnet-turbo.toml"

# Buat file service untuk systemd
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

# Reload systemd, enable, dan start service
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl restart zgs

# Tampilkan status service
sudo systemctl status zgs --no-pager

# Tampilkan logs node secara real-time
tail -f "$HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)" &

# Jalankan monitoring dalam screen session
screen -dmS zgs_monitor bash -c '
while true; do
    response=$(curl -s -X POST http://localhost:5678 -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"method\":\"zgs_getStatus\",\"params\":[],\"id\":1}");
    logSyncHeight=$(echo $response | jq ".result.logSyncHeight");
    connectedPeers=$(echo $response | jq ".result.connectedPeers");
    echo -e "logSyncHeight: \033[32m$logSyncHeight\033[0m, connectedPeers: \033[34m$connectedPeers\033[0m";
    sleep 5;
done'

echo "Instalasi Go, Rust, 0g-storage-node selesai, proses build selesai, konfigurasi telah diunduh, private key telah ditambahkan, service telah dibuat dan dijalankan, monitoring node berjalan dalam screen session!"
