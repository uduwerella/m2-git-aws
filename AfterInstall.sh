#!/bin/bash
NEWREVISION="/var/www/html/latest"
DEPLOYPATH="/var/www/html"
RELEASES="/var/www/html"
SHARED="$DEPLOYPATH/shared"
SYMNAME="current"
WPSHARED="/var/www/html/wp-shared"

cd $RELEASES
checkl(){
        SPATH=$1
        PATHTOCHECK=$2
        if [ ! -L "$PATHTOCHECK" ]; then
        ln -s $SPATH $PATHTOCHECK
        fi
        }

checkd(){
        SPATH=$1
        PATHTOCHECK=$2
        if [ ! -d "$PATHTOCHECK" ]; then
        cp -pr $SPATH $PATHTOCHECK
        fi
        }

rm $NEWREVISION/app/etc/env.php
checkl $SHARED/app/etc/env.php $NEWREVISION/app/etc/env.php
#checkl $SHARED/pub/static/deployed_version.txt $NEWREVISION/pub/static/deployed_version.txt
# Need to get the file from Bitbucket # rm $NEWREVISION/app/etc/config.php
#checkl $SHARED/app/etc/config.php $NEWREVISION/app/etc/config.php
rm $NEWREVISION/pub/media
mv $NEWREVISION/pub/media $NEWREVISION/pub/media-git
checkl $SHARED/pub/media-empty $NEWREVISION/pub/media
checkl $SHARED/var/log $NEWREVISION/var/log

checkd $SHARED/pub/en $NEWREVISION/pub/en
checkd $SHARED/pub/ar $NEWREVISION/pub/ar
checkl $SHARED/pub/static/_cache $NEWREVISION/pub/static/_cache

rm $NEWREVISION/var/log
mv $NEWREVISION/var/log $NEWREVISION/var/log-build
checkl $SHARED/var/log $NEWREVISION/var/log

touch $SHARED/qa-maintenance-page/maintenance.enable
touch $SHARED/kw-maintenance-page/maintenance.enable
touch $SHARED/sa-maintenance-page/maintenance.enable
touch $SHARED/bh-maintenance-page/maintenance.enable

cd $NEWREVISION && php bin/magento setup:upgrade >> $NEWREVISION/setup-upgrade.log

rm $NEWREVISION/pub/media
ln -s $SHARED/pub/media $NEWREVISION/pub/media



cd $NEWREVISION && php bin/magento setup:di:compile > $NEWREVISION/di-compile.log
cd $NEWREVISION && php bin/magento setup:static-content:deploy -j 1> $NEWREVISION/static-content-deploy.log
cd $NEWREVISION && php bin/magento setup:di:compile > $NEWREVISION/di-compile.log


chmod -R 775 $NEWREVISION/pub/static
chmod -R 777 $NEWREVISION/var
chmod -R 777 $NEWREVISION/vendor
chmod -R 775 $NEWREVISION/generated/
setfacl -R -m d:u:magento:rwx $NEWREVISION/var/generation
setfacl -R -m d:u:www-data:rwx $NEWREVISION/var/generation
setfacl -R -m d:g:www-data:rwx $NEWREVISION/var/generation
setfacl -R -m d:u:www-data:rwx $NEWREVISION/generated/
setfacl -R -m d:g:www-data:rwx $NEWREVISION/generated/
setfacl -R -m d:u:magento:rwx $NEWREVISION/vendor
setfacl -R -m d:u:www-data:rwx $NEWREVISION/vendor
setfacl -R -m d:g:www-data:rwx $NEWREVISION/vendor

cd $RELEASES
chown -R magento:www-data $NEWREVISION
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
if [ -d "$RELEASES/current" ]; then
mv $DEPLOYPATH/current $DEPLOYPATH/last_1
fi
touch $SHARED/qa-maintenance-page/maintenance.enable
touch $SHARED/kw-maintenance-page/maintenance.enable
touch $SHARED/sa-maintenance-page/maintenance.enable
touch $SHARED/bh-maintenance-page/maintenance.enable

if [ -d "$NEWREVISION" ]; then
mv $NEWREVISION $DEPLOYPATH/current
sudo -u  magento php $DEPLOYPATH/current/bin/magento cache:flush
chmod -R 777 $DEPLOYPATH/current/var
chmod -R 777 $DEPLOYPATH/current/var/cache
#/usr/local/bin/varnishflush
fi
touch $SHARED/qa-maintenance-page/maintenance.enable
touch $SHARED/kw-maintenance-page/maintenance.enable
touch $SHARED/sa-maintenance-page/maintenance.enable
touch $SHARED/bh-maintenance-page/maintenance.enable
rm -fr $RELEASES/deleting
rm $SHARED/qa-maintenance-page/maintenance.enable
rm $SHARED/kw-maintenance-page/maintenance.enable
rm $SHARED/sa-maintenance-page/maintenance.enable
rm $SHARED/bh-maintenance-page/maintenance.enable
systemctl restart php7.2-fpm
/var/www/html/shared/deploy/deploy-completed.sh
