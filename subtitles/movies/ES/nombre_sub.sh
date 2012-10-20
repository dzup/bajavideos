#!/bin/bash
#
#

for ARCHIVO in * ; do
        echo $ARCHIVO | sed 's/_.*//g'
        NOMBRE=$(cat ../../../db/freevana.txt | grep "VALUES($(echo $ARCHIVO | sed 's/_.*//g')," | head -n 1 \
        | cut -d"'" -f 2)
        cp $ARCHIVO "${NOMBRE}_ES.srt"
        echo  "${NOMBRE}_ES.srt"
        #ompload "${NOMBRE}_ES.srt"
        #sleep 30
done
