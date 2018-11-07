#!/usr/bin/env bash

# Togo PrivateSend (Coin Mixing) Liquidity Provider Script/Guide

# Reference: https://wiki.biblepay.org/PrivateSend

#################
# Instructions
#
# 1. Rent a Cloud Server (Ex: Vultr Ubuntu 18.04)
#
# 2. Download the script to the server:
#
# cd /home  
# wget https://raw.githubusercontent.com/togoshigekata/biblepay-files/master/liquid-install-togo.sh
#
# 3. Ensure script is executable:
#
# chmod 777 liquid-install-togo.sh
#
# 4. Run the script:
#
# ./liquid-install-togo.sh
#
#################

# CONFIG:
# keypool=100000
# createwalletbackups=5
# shrinkdebugfile=1
# enableprivatesend=1
# privatesendamount=1000000
# privatesendrounds=8
# privatesendmultisession=1
# #liquidityprovider=1

# NOTE: Script uses multisession instead of liquidityprovider since it is 10-15x faster
# NOTE: liquidityprovider=1 will override privatesendmultisession=1, just uncomment it

# NOTE: If you want to run your liquidity provider encrypted, you may have to run as GUI until this bug is fixed
# https://github.com/dashpay/dash/pull/2102/commits/9560354298be0e8ee29d741a4a3b8ca62ddc7418

# NOTE: At 100k keys, wallet.dat file is about 30-40MB in size (each backup will be this size too!)


COINDAEMON=biblepayd
COINCLIENT=biblepay-cli

COINCORE=.biblepaycore
COINCONFIG=biblepay.conf


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

cd /home/biblepay/src
$COINDAEMON -daemon #> /dev/null 2>&1
sleep 120
$COINCLIENT stop #> /dev/null 2>&1

echo -e "keypool=100000\ncreatewalletbackups=5\nshrinkdebugfile=1\nenableprivatesend=1\nprivatesendamount=1000000\nprivatesendrounds=8\nprivatesendmultisession=1\n#liquidityprovider=1" > ~/$COINCORE/$COINCONFIG

$COINDAEMON -daemon #> /dev/null 2>&1
sleep 240
$COINCLIENT getinfo
$COINCLIENT stop #> /dev/null 2>&1

echo -e "2. ENCRYPT  ./biblepay-cli encryptwallet password"
echo -e "3. UNLOCK   ./biblepay-cli walletpassphrase password 600" # seconds
echo -e "4. REFILL   ./biblepay-cli keypoolrefill" # think it auto refills after config change, restart and passphrase entered
echo -e "5. BACKUP   Locally: Windows: use WinSCP, Linux: scp root@IP:~/.biblepaycore/wallet.dat wallet.dat.X.backup"
echo -e "6. GETADDR  ./biblepay-cli getnewaddress" # can keep running this command to get many more
echo -e "7. SEND     Locally: Send coins to addresses for mixing, Remote: Confirm recieved ./biblepay-cli listtransactions"
echo -e "8. UNLOCK   ./biblepay-cli walletpassphrase password 600000" # add parameter "true" to only unlock mixing # bug, cant use
echo -e "9. MIXING   ./biblepay-cli privatesend start" # also "stop" and "reset" commands
echo -e "*** MIX COINS ***"
echo -e "10. PRIVATESEND   ./biblepay-cli sendtoaddress ADDRESS AMOUNT "" "" false false true" # last parameter sets as privatesend transaction
