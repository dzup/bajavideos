#!/bin/bash
#
#       sube archivos a archive.org
#
# siznax 2012, Modificado por bazza
#
#
#

if [ $# -lt 4 ]; then
    echo "Usage: "`basename $0`" item srcfile mediatype desc [coll]"
    echo "      item: sin espacios"
    echo "      mediatype: [image|audio|movies|texts]"
    exit 0
fi

if [ ! -f ~/.s3cfg ]; then

# Api key de tu usuario
echo "necesitas la configuracion en ~/.s3cfg"
echo "access_key = clave
secret_key = clave"

fi

keyfile=~/.s3cfg # see archive.org/help/abouts3.txt
item=$1          # Internet Archive item name
srcfile=$2       # local file to upload
mediatype=$3     # audio image movies text software other
desc=$4          # description

# see below for IA collections and mediatypes
# http://archive.org/advancedsearch.php

tgtfile=${srcfile} # could make this an arg

if [ $# -gt 4 ]
then
    coll1=$5
else
    coll1="opensource" # a collection is required
fi

date
start=`date +%s`

src_md5=`md5sum ${srcfile} | cut -d ' ' -f 1` # Mac OS X
echo "${srcfile} ${src_md5}"

s3base=s3.us.archive.org
dlbase=www.archive.org
bucket=http://${s3base}/${item}/${tgtfile}

collections[1]="--header 'x-archive-meta01-collection:${coll}' "
#collections[2]="--header 'x-archive-meta02-collection:coll2' "
#collections[3]="--header 'x-archive-meta03-collection:coll3' "

if [ ! -f ${keyfile} ]; then exit 2; fi
accesskey=`grep access_key $keyfile | cut -d ' ' -f 3`
secretkey=`grep secret_key $keyfile | cut -d ' ' -f 3`

echo bucket: ${bucket}
curl -s --location\
 --header 'x-amz-auto-make-bucket:1'\
 --header "x-archive-meta-mediatype:${mediatype}"\
 --header 'x-archive-queue-derive:0'\
 --header "x-archive-meta-description:${desc}"\
 ${collections[@]}\
 --header "authorization: LOW ${accesskey}:${secretkey}"\
 --upload-file ${srcfile}\
 ${bucket}

metafile=http://${dlbase}/download/${item}/${tgtfile}_meta.txt
echo metafile: $metafile
echo item: http://${dlbase}/details/${item}

# it can take some time for the S3 meta file to become available
# could consider doing verification in a separate step

echo "verifying upload..."

delay=15
limit=5
retry=0
abort=0
while [ `curl -L -w %{http_code} -s -o /dev/null $metafile` -ne 200  ]; do
    ((retry++))
    if [ $retry -eq $limit ]; then
        echo "ABORT verify checksum"
        echo $((`date +%s`-start)) seconds
        exit 1
    fi
    echo "retry ${retry} wait ${delay}"
    sleep ${delay}
done

tgt_md5=`curl -s -L ${metafile} | grep -i ETag | cut -d \" -f 2`
length=`curl -s -L ${metafile} | grep -i content-length | cut -d ' ' -f 2`

if [ "${tgt_md5}" == "${src_md5}" ]; then
    echo "OK ${tgtfile} ${tgt_md5}"
else
    echo $metafile
    echo "CHECKSUM ERR src/${src_md5} tgt/${tgt_md5}"
fi

echo ${length} bytes $((`date +%s`-start)) seconds
