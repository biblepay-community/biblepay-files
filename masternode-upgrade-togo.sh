#!/bin/bash 

IP=XXXXXXX
NUMBER=1

# Togo Masternode Upgrade Script

# PRE-SETUP:  
# ssh-keygen -t rsa -b 4096 #Generate SSH Key
# ssh-copy-id root@IP

#################
# Instructions
#
# 1. Download the script:
#
# cd /home  
# wget https://raw.githubusercontent.com/togoshigekata/biblepay-files/master/masternode-upgrade-togo.sh
#
# 2. Ensure script is executable:
#
# chmod 777 masternode-upgrade-togo.sh
#
# 3. Edit the Masternode IP Address variable in the script
#
# 4. Run the script:
#
# ./masternode-upgrade-togo.sh
#
#################

# NOTE: Ubuntu - How to double click executable:
# https://askubuntu.com/questions/286621/how-do-i-run-executable-scripts-in-nautilus


echo "========== Upgrading Masternode #$NUMBER - " $IP

echo "==== Stop & Kill Daemon"
ssh root@$IP /home/biblepay/src/biblepay-cli stop
sleep 10
ssh root@$IP pkill -9 -f ^'/home/biblepay/src/biblepayd'
sleep 10

echo "==== Pull Latest Code"
ssh root@$IP git -C /home/biblepay/src pull origin master
sleep 10

echo "==== Setup 2GB Swap File"
ssh root@$IP free
sleep 10
ssh root@$IP dd if=/dev/zero of=/var/swap.img bs=2048k count=1000
sleep 10
ssh root@$IP mkswap /var/swap.img
sleep 10
ssh root@$IP swapon /var/swap.img
sleep 10
ssh root@$IP free 
sleep 10

echo "==== Compile Code"
ssh root@$IP make -C /home/biblepay/src
sleep 10

echo "==== Start Daemon - Masternode #$NUMBER"
ssh root@$IP /home/biblepay/src/biblepayd -daemon
sleep 120
ssh root@$IP /home/biblepay/src/biblepay-cli getinfo

echo "========== Finished Upgrading Masternode #$NUMBER"
sleep 1200
