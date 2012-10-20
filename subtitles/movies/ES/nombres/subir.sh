#!/bin/bash
#
#

for ARCHIVO in * ; do
        ompload "$ARCHIVO"
        sleep 120
done
