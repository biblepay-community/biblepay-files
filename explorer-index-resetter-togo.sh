#!/bin/bash

##############
# Setup: 
#
# crontab -e
# */4 * * * * /home/explorer-index-resetter-togo.sh > /dev/null 2>&1
#
# Full Crontab with BiblePay Daemon and Mongo Service Checking:
#
# */2 * * * * cd /home/explorer && /usr/bin/nodejs --stack-size=15000 scripts/sync.js index update > /dev/null 2>&1
# */6 * * * * cd /home/explorer && /usr/bin/nodejs scripts/sync.js market > /dev/null 2>&1
# */11 * * * * cd /home/explorer && /usr/bin/nodejs scripts/peers.js > /dev/null 2>&1
#
# */5 * * * * /home/biblepay/src/biblepayd > /dev/null 2>&1
# */4 * * * * /home/explorer-index-resetter-togo.sh > /dev/null 2>&1
# 0 */3 * * * /usr/sbin/service mongod start > /dev/null 2>&1
##############

fname="/home/explorer/tmp/index.pid"

if [[ -f "$fname" ]];
then
        pid=$(</home/explorer/tmp/index.pid)
        echo $pid
        ps -p $pid > /dev/null
        r=$?
        echo $r
        if [ $r -eq 0 ]; then
                exit 1
        else
                rm $fname
        fi
fi
