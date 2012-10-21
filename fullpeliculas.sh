#!/bin/bash
#
#       Basado en un script de dzup - u3mx
#
#       Descarga las paginas y va creando una carpeta por pelicula, con su descripcion y poster
#

url="http://www.fullpeliculas.tv/page/"
for i in $(seq 27); do
        wget "$url/$i" -O - 2> /dev/null \
        | grep "<a class=\"pelicula\" href=\"http://www.fullpeliculas.tv/" \
        | grep -oe '<a class=\"pelicula\" href=\"[^"]*\.html' \
        | sed -e "s/[<]a class=\"pelicula\" href=\"//g" | while read m; do

                wget $m -qO peli 1> /dev/null
                recode iso-8859-1 peli

                tit=`grep "[<]title[>]" peli|sed -e "s/<title>//g"\
                | sed -e "s/<\/title>//g"|sed -r 's/Ver\ //g'|sed -r 's/[Oo]nline//g'`
                titulo=$(echo "$tit"|sed -r "s/'/\\\'/g"|sed 's/ $//')
                ano=$(grep "A*o: " peli|sed 's/<[^>]*>//g')
                duracion=$(grep Duraci.*n: peli | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
                reparto=$(grep "Reparto:" peli | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
                generos=$(grep G.*nero.: peli | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
                sinopsis=$(echo $(grep "[Ss]inopsis" peli \
                | sed -e :a -e 's/<[^>]*>//g;/</N;//ba' | sed -e 's/<[^>]*>.*//g'|sed -r "s/'/\\\'/g"))
                solonombre=$(echo $(echo "$titulo"|sed -e "s/ /-/g"|sed -r "s/'/\\\'/g;"))

                if [ ! -f $solonombre.txt ]; then

                        for b in `grep "iframe src" peli|grep -oe 'vk.com[^"]*'`;do
                                f="http://"$(echo $b|sed -e 's/\\//g')
                        done

                        # sacar esta miniatura de un banco de datos
                        wget -q $(grep "http://www.fullpeliculas.tv" peli | grep ".jpg" | grep -oe '[^"]*\.jpg' | uniq)\
                         -O $solonombre.jpg

                        echo $solonombre

# completar esta descripcion con un banco de datos
echo "Titulo: $titulo
$ano
$duracion
$sinopsis
$reparto
$generos
URL: $f
" > $solonombre.txt

        fi
                done
        done
exit

Es un programa que me paso dzup en #lab y lo modicique para que sea mas simple
