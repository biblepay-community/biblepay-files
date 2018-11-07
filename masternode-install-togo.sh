#!/usr/bin/env bash

# Togo Quick Masternode Install Script

#################
# Instructions
#
# 1. Rent a Cloud Server (Ex: Vultr Ubuntu 18.04)
#
# 2. Download the script to the server:
#
# cd /home  
# wget https://raw.githubusercontent.com/togoshigekata/biblepay-files/master/masternode-install-togo.sh
#
# 3. Ensure script is executable:
#
# chmod 777 masternode-install-togo.sh
#
# 4. Run the script:
#
# ./masternode-install-togo.sh
#
#################

# Credit:
# https://raw.githubusercontent.com/biblepay/biblepay/master/contrib/masternode-install.sh

# Differences:
# - Removed all user prompts
# - View output of every command
# - Uses /home folder
# - Uses old wallet install commands
# - Set swap file to 2GB
# - Added pkill for stopping daemon


rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
rpcpass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

COINRPCPORT=9998
COINPORT=40000


echo -e "1. FIREWALL"
sudo apt-get -y install ufw #> /dev/null 2>&1
sudo ufw allow ssh/tcp #> /dev/null 2>&1
sudo ufw limit ssh/tcp #> /dev/null 2>&1
sudo ufw allow $COINPORT/tcp #> /dev/null 2>&1
sudo ufw allow $COINRPCPORT/tcp #> /dev/null 2>&1
echo "y" | sudo ufw enable #> /dev/null 2>&1
echo -e "1. DONE";


echo -e "2. INSTALL WALLET"
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install -y libdb4.8-dev libdb4.8++-dev
sudo apt-get install -y automake
sudo apt-get install -y bsdmainutils
sudo apt-get install -y g++
sudo apt-get install -y git
sudo apt install -y make
sudo apt-get install -y build-essential
sudo apt-get install -y autoconf libtool pkg-config
sudo apt-get install -y libboost-all-dev libssl-dev libevent-dev
sudo apt-get install -y libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler

cd /home
git clone https://github.com/biblepay/biblepay

BP_ROOT=$(pwd)
BDB_PREFIX="${BP_ROOT}/db4"
mkdir -p $BDB_PREFIX

wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz'
echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c
tar -xzvf db-4.8.30.NC.tar.gz
cd db-4.8.30.NC/build_unix
../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX
make install

cd $BP_ROOT
cd biblepay
sudo chmod 777 share/genbuild.sh
sudo chmod 777 autogen.sh

./autogen.sh
./configure LDFLAGS="-L${BDB_PREFIX}/lib/" CPPFLAGS="-I${BDB_PREFIX}/include/"

free
dd if=/dev/zero of=/var/swap.img bs=2048k count=1000
mkswap /var/swap.img
swapon /var/swap.img
free

sudo make

/home/biblepay/src/biblepayd -daemon
sleep 120
/home/biblepay/src/biblepay-cli  stop
sleep 20
pkill -9 -f ^'/home/biblepay/src/biblepayd'
echo -e "2. DONE";


echo -e "3. CONFIGURE WALLET"
mnip=$(curl --silent ipinfo.io/ip)
echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcallowedip=127.0.0.1\nlisten=1\nserver=1\ndaemon=1" > ~/.biblepaycore/biblepay.conf
/home/biblepay/src/biblepayd -daemon #> /dev/null
sleep 120
mnkey=$(/home/biblepay/src/biblepay-cli masternode genkey)
/home/biblepay/src/biblepay-cli stop #> /dev/null
sleep 20
pkill -9 -f ^'/home/biblepay/src/biblepayd'
sleep 2
echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcport=${COINRPCPORT}\nrpcallowip=127.0.0.1\nlogtimestamps=1\nshrinkdebuglog=1\ndaemon=1\nserver=1\nlisten=1\nmasternode=1\nexternalip=${mnip}\nmaxconnections=256\nmasternodeprivkey=${mnkey}\n" > ~/.biblepaycore/biblepay.conf
echo -e "3. DONE";


echo -e "4. INSTALL WATCHMAN"
if crontab -u $USER -l|grep -q watchman.py; then 
    echo -e "watchman already present..."
else 
    sudo apt update #> /dev/null 2>&1
    sudo apt -y install git python-virtualenv virtualenv
    cd ~/.biblepaycore
    git clone https://github.com/biblepay/watchman.git #> /dev/null 2>&1
    cd watchman
    virtualenv venv --python=python3 #> /dev/null 2>&1
    venv/bin/pip install -r requirements.txt #> /dev/null 2>&1
    #write out current crontab
    crontab -u $USER -l > mycron
    echo "* * * * * cd ~/.biblepaycore/watchman && ./venv/bin/python bin/watchman.py >/dev/null 2>&1" >> mycron
    crontab mycron #> /dev/null 2>&1
    rm mycron        
fi
sleep 2
echo -e "4. DONE";


echo -e "================================================================================================"
echo -e "${BOLD}Masternode IP:${NONE} ${mnip}:${COINPORT}"
echo -e "${BOLD}Masternode Private Key:${NONE} ${mnkey}"
echo -e "${BOLD}Continue with the rest of the setup on the wiki${NONE}"
echo -e "================================================================================================"

/home/biblepay/src/biblepayd -daemon
#sleep 600
#/home/biblepay/src/biblepay-cli  stop

