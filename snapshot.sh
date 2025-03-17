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

# Membuat screen untuk snapshot
echo -e "${CYAN}Membuat screen untuk snapshot...${NC}"
screen -dmS snapshot bash -c '
    sudo apt-get update && 
    sudo apt-get install wget lz4 aria2 pv -y && 
    cd $HOME && 
    rm -f storage_0gchain_snapshot.lz4 && 
    aria2c -x 16 -s 16 -k 1M https://josephtran.co/storage_0gchain_snapshot.lz4 && 
    echo -e "${GREEN}Download selesai. Menjalankan ekstraksi snapshot...${NC}" && 
    rm -rf $HOME/0g-storage-node/run/db && 
    lz4 -c -d storage_0gchain_snapshot.lz4 | pv | tar -x -C $HOME/0g-storage-node/run && 
    echo -e "${GREEN}Ekstraksi selesai. Restarting node...${NC}" && 
    sudo systemctl restart zgs
'

echo -e "${CYAN}Screen telah dibuat. Anda bisa kembali dengan menjalankan: screen -r snapshot${NC}"
echo -e "${YELLOW}Untuk keluar dari screen tanpa menghentikan proses, tekan CTRL + A + D.${NC}"
