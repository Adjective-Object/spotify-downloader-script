#!/usr/bin/env bash

####
# filter for duplicate lines (adjacent AND non-adjacent), preserving input
# order
 uniqx() {
    awk '{ if (!h[$0]) { print $0; h[$0]=1 } }'
 }


LISTFILE="$(date '+%Y-%m-%d')-automatic.txt"
LINES=`node ./spot.js ${@}`
echo "$LINES" >> $LISTFILE
LISTFILE_CONTENT=$(cat $LISTFILE)
echo "$LISTFILE_CONTENT" | uniqx > $LISTFILE

echo "added to listfile $LISTFILE:"
echo "$LINES"
