#!/bin/bash
curl -s https://api.ondex.app/logo.sh | bash

echo "=================================================="

sleep 2

echo -e "\e[1m\e[32m1. Stopping the FullNode \e[0m" && sleep 1

# Installing yq to modify yaml files
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64  &> /dev/null
sudo chmod a+x /usr/local/bin/yq

cd $HOME/aptos
sudo docker compose down -v
sudo docker pull aptoslab/validator:devnet

# Renew node identity to 32 byte formated key
ID=$(cat $HOME/aptos/identity/id.json | jq -r '.Result[].keys[]')
echo "---
"$ID":
  addresses: []
  keys:
    - "$ID"
  role: Downstream" > $HOME/aptos/identity/peer-info.yaml
/usr/local/bin/yq e -i '.full_node_networks[].identity.peer_id="'$ID'"' $HOME/aptos/public_full_node.yaml

# Renew seeds
wget -P $HOME/aptos https://github.com/ceuit/aptos/blob/main/seeds.yaml  &> /dev/null
/usr/local/bin/yq ea -i 'select(fileIndex==0).full_node_networks[0].seeds = select(fileIndex==1).seeds | select(fileIndex==0)' $HOME/aptos/public_full_node.yaml $HOME/aptos/seeds.yaml
rm $HOME/aptos/seeds.yaml

echo "=================================================="

echo -e "\e[1m\e[32m2. Downloading new genesis and waypoint configs \e[0m" && sleep 1

rm $HOME/aptos/genesis.blob
wget -P $HOME/aptos https://devnet.aptoslabs.com/genesis.blob

rm $HOME/aptos/waypoint.txt
wget -P $HOME/aptos https://devnet.aptoslabs.com/waypoint.txt

echo "=================================================="

echo -e "\e[1m\e[32m3. Setting a new waypoint param in the public_full_node.yaml file \e[0m" && sleep 1

sed -i.bak 's/\(from_config: \).*/\1"'$(cat $HOME/aptos/waypoint.txt)'"/g' $HOME/aptos/public_full_node.yaml

echo "=================================================="

echo -e "\e[1m\e[32m4. Restarting the node \e[0m" && sleep 1

sudo docker compose up -d

echo "=================================================="

echo -e "\e[1m\e[32m5. Aptos FullNode Started \e[0m"

echo "=================================================="

echo -e "\e[1m\e[32mTo check sync status: \e[0m" 
echo -e "\e[1m\e[39m    curl 127.0.0.1:9101/metrics 2> /dev/null | grep aptos_state_sync_version | grep type \n \e[0m" 

echo -e "\e[1m\e[32mTo view logs: \e[0m" 
echo -e "\e[1m\e[39m    docker logs -f aptos-fullnode-1 --tail 5000 \n \e[0m" 

echo -e "\e[1m\e[32mTo stop: \e[0m" 
echo -e "\e[1m\e[39m    docker compose stop \n \e[0m" 