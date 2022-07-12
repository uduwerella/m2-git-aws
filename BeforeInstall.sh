#!/bin/bash
/var/www/html/shared/deploy/deploy.sh
NEWREVISION="/var/www/html/latest"

if [ ! -d "$NEWREVISION" ]; then
mkdir $NEWREVISION -p
exit 0;
fi
rm -fr $NEWREVISION
mkdir $NEWREVISION -p
