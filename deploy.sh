#!/bin/bash
NEWREVISION="/var/www/latest"
DEPLOYPATH="/var/www"
RELEASES="/var/www"
SHARED="$DEPLOYPATH/shared"
SYMNAME="crashbaggage"

if [ ! -d "$NEWREVISION" ]; then
mkdir $NEWREVISION -p
fi

cd $RELEASES


checkl(){
        SPATH=$1
        PATHTOCHECK=$2
        if [ ! -L "$PATHTOCHECK" ]; then
        ln -s $SPATH $PATHTOCHECK
        fi
        }

checkf(){
        SPATH=$1
        PATHTOCHECK=$2
     #   if [ ! -f "$PATHTOCHECK" ]; then
        cp -p $SPATH $PATHTOCHECK
     #   fi
        }

checkd(){
        SPATH=$1
        PATHTOCHECK=$2
        if [ ! -d "$PATHTOCHECK" ]; then
        cp -pr $SPATH $PATHTOCHECK
        fi
        }


checkl $SHARED/app/etc/env.php $NEWREVISION/app/etc/env.php
checkl $SHARED/pub/static/deployed_version.txt $NEWREVISION/pub/static/deployed_version.txt
checkl $SHARED/app/etc/config.php $NEWREVISION/app/etc/config.php

mv $NEWREVISION/pub/media $NEWREVISION/pub/media-git
checkl $SHARED/pub/media-empty $NEWREVISION/pub/media
checkl $SHARED/var/log $NEWREVISION/var/log
#checkd $SHARED/pub/static/frontend/Ascentic/raid/en_GB $NEWREVISION/pub/static/frontend/Ascentic/raid/en_GB
#checkl $SHARED/pub/static/_cache $NEWREVISION/pub/static/_cache
#Stopping traffic
sudo systemctl restart php7.1-fpm.service
#/usr/local/bin/varnishflush
php $DEPLOYPATH/crashbaggage/bin/magento cache:flush
cd $NEWREVISION && php bin/magento setup:upgrade > $NEWREVISION/setup-upgrade.log
if [[ $? -ne 0 ]]
        then echo "error running setup upgrade"
	rm -fr $NEWREVISION;
        exit 1;
fi
rm $NEWREVISION/pub/media
ln -s $SHARED/pub/media $NEWREVISION/pub/media
cd $NEWREVISION && php bin/magento setup:di:compile > $NEWREVISION/di-compile.log
if [[ $? -ne 0 ]]
        then echo "error running di:compile"
	rm -fr $NEWREVISION;
        exit 1;
fi
echo "DI Over going to Static-Content:deploy"
cd $NEWREVISION && export HTTPS=on;php bin/magento setup:static-content:deploy -f en_GB en_US -j 1 | stdbuf -o0 tr -d . > $NEWREVISION/static-content-deploy.log
#cd $NEWREVISION && export HTTPS=on;php bin/magento setup:static-content:deploy en_US -j 1 | stdbuf -o0 tr -d . > $NEWREVISION/static-content-deploy.log
if [[ $? -ne 0 ]]
        then echo "error running static:content:deploy"
	rm -fr $NEWREVISION;
        exit 1;
fi
#checkf $NEWREVISION/pub/static/deployed_version.txt $SHARED/pub/static/deployed_version.txt
chmod -R 777 $SHARED/pub/static/deployed_version.txt
rm $NEWREVISION/pub/static/deployed_version.txt
checkl $SHARED/pub/static/deployed_version.txt $NEWREVISION/pub/static/deployed_version.txt
cd $RELEASES
rm $NEWREVISION/var/log
mv $NEWREVISION/var/log $NEWREVISION/var/log-build
checkl $SHARED/var/log $NEWREVISION/var/log


chmod -R 775 $NEWREVISION/pub/static
chmod -R 777 $NEWREVISION/var

cd $RELEASES
if [ -d "$RELEASES/last_5" ]; then
mv $RELEASES/last_5 $RELEASES/deleting
fi
if [ -d "$RELEASES/last_4" ]; then
mv $RELEASES/last_4 $RELEASES/last_5
fi
if [ -d "$RELEASES/last_3" ]; then
mv $RELEASES/last_3 $RELEASES/last_4
fi
if [ -d "$RELEASES/last_2" ]; then
mv $RELEASES/last_2 $RELEASES/last_3
fi
if [ -d "$RELEASES/last_1" ]; then
mv $RELEASES/last_1 $RELEASES/last_2
fi



if [ -d "$RELEASES/crashbaggage" ]; then
mv $DEPLOYPATH/crashbaggage $DEPLOYPATH/last_1
fi
if [ -d "$NEWREVISION" ]; then
mv $NEWREVISION $DEPLOYPATH/crashbaggage
fi
sudo systemctl restart php7.1-fpm.service

rm -fr $RELEASES/deleting

