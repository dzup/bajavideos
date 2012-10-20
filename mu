#!/bin/bash
#
#	Programa para descargar cosas de megaupload
#
#       Ernesto Bazzano (El Bazza) Licencia AGPL
#

head="movil Mozilla/5.0 (X11; U; Linux i686; es-CL; rv:1.9.2.13) Gecko/20101206 Ubuntu/10.10 (maverick) Firefox/3.6.13"
limite="--limit-rate=140k"

if [ "$1" ]; then

	echo "Espera por favor..."
	VIDEO=$(wget "$1" -q -O - | \
	awk -F'>' '/^a href/{split($1,F,"\"");print F[2],$NF}' RS='<' | grep megaupload.com/files)
	if [ "$VIDEO" == "" ];then
		echo ">[:(] el link no anda mas"
		exit 2
	fi

	# espera
	#for i in $(seq 1 65) ; do sleep 1; echo -n "$i "; done
	cd "$HOME/Descargas"
	wget -e robots=off --user-agent="$head" $limite $proxy "$VIDEO"

else
	echo "uso: mu 'http://megaupload.com'" [-proxy]
fi


exit

#!/bin/bash
#
# Programa para descargar cosas de megaupload
#
head="movil Mozilla/5.0 (X11; U; Linux i686; es-CL; rv:1.9.2.13) Gecko/20101206 Ubuntu/10.10 (maverick) Firefox/3.6.13"

limite="--limit-rate=140k"

if [ "$1" ]; then

	echo "Espera por favor..."
	VIDEO=$(wget -e robots=off --user-agent="$head"  -q $1 -O - | grep -m 1 downloadlink \
	| grep -o http.* | sed 's/\".*//;s/" "/%20/g')
	if [ "$VIDEO" == "" ];then
		echo ">[:(] el link no anda mas"
		exit 2
	fi
	bajo=""
	# for i in $(seq 1 40) ; do sleep 1; echo -n "$i "; done
	cd "$HOME/Descargas"
	NOMBRE="$(echo "$VIDEO" | sed 's/.*\/\(.*\)$/\1/g; s/&//g;s/\[www\..*\]//g; s/\(www\..*\)//g')"
	echo -e "\n $NOMBRE descargando..."
	if [ "$NOMBRE" ];then
		NOMBREO="-O $NOMBRE"
	else
		NOMBREO=""
	fi

	wget -e robots=off --user-agent="$head" --waitretry=420 --tries=6 $limite $proxy "$VIDEO" "$NOMBREO"

else
	echo "uso: mu 'http://megaupload.com'" [-proxy]
fi
