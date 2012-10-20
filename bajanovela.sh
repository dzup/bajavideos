#!/bin/bash
# http://vertelenovelas.net
# bajanovela.sh
#


version="0.0.1b"
echo "$0 Ver. $version echo por dzup"
echo "Uso:"
echo "$0 \"titulo\" \"Año\" \"televisora\""


#cambiar estos valores
#url="http://vertelenovelas.net/la-reina-del-sur.html"
#baseurl="http://vertelenovelas.net/"
#generos="tv, tvnovela,televisa"
#ano="2012"
#hoy="2012-10-15"
#out="la-reina-del-sur.sql"


lenombre="$1"
ano="$2"
televisora=", $3"

if [[ "$1" = "" ]] || [[ "$1" = "-h" ]]; then
	exit 1
fi

url="http://vertelenovelas.net/$lenombre.html"
baseurl="http://vertelenovelas.net/"
generos="tv, telenovela, tvnovela$televisora"

hoy="2012-10-15"

#0 regular 
#1 vk.com
#2 http://www.dailymotion.com
#Para no sobreescribir, Modifica el nombre.sql ...añadale algo
tipo=2

out="$lenombre.sql"


#no existe default caratula
non_existing="http://u3mx.com/images/imagen-no-existe.jpg"

tmpfile="$0.html"
dircar="$0-dir/"   #directorio de peliculas

#everytime a new record is addit, this
#file its add by #number
#so, at the ent cat $log | uniq to verify if all numbers been add
log="$0.log"

reg=0
# crea directorios si no existen
mkdir -p $dircar
:>$out
:>$log

#1 doesn't download files
#0 does
debug=0;

## funciones

bajaurl(){
        wget -O- - $1 --quiet
}

makeutf8(){
	recode iso-8859-1.. < $1 > $1.tmp
	rm $1
	mv $1.tmp $1
}

gettitle(){
	tit=`grep "[<]title[>]" $tmpfile|sed -e "s/<title>//g"|sed -e "s/<\/title>//g"|sed 's/"//g'|sed -r "s/'/\\\'/g"|sed 's/<[^>]*>//g'`
	titulo=$(echo "$tit"|sed -r "s/'/\\\'/g"|sed 's/ $//'|sed 's/ $//g'|sed 's/"/\\"/g'|sed 's/ $//'|sed 's/ $//g')
	echo $titulo
}

ltrim(){
	##trim left spaces
	echo "$1" | sed 's/^ *//g'
}

rtrim(){
	##trim right spaces
	echo "$1" | sed 's/^ *//'
}

trim_rl(){
	##trim right and left spaces
	tmp=$(rtrim "$1")
	echo $(ltrim "$tmp")
}

trim_all(){
	##trim al spaces
	echo "$1" | sed 's/ //g'
}

esc_s(){
	##escape single ' with \'
	echo "$1" | sed -r "s/'/\\\'/g"
}

esc_d(){
	##escape single ' with \'
	echo "$1" | sed -r 's/"/\\\"/g'
}

fix_slash(){
	##escape single / with \/
	echo "$1" | sed -r 's/\//\\\//g'
}

fix_backslash(){
	##escape single / with \/
	echo "$1" | sed -r 's/\\/\\\\/g'
}

esc_fix_commas(){
	tmp=$(esc_s "$1")
	echo $(esc_d "$tmp")
}

fix_html_tags(){
	#remove all html tags
	echo "$1" | sed 's/<[^>]*>//g'
}

fix_filename(){
	#takeoff bad characters of filenames
	echo "$1" | sed -r 's/[\/:*?"<>|]//g'
}

get_caratula_url(){
	##<meta property="og:image" content="
	echo $(grep '<meta property="og:image" content="' $1 | grep -oe 'http://[^"]*')
}

get_sinopsis(){
	##Sinopsis:
	echo $(grep "Sinopsis:" $1 | sed -e 's/Sinopsis: //g')
}

fix_sinopsis(){
	 tmp=$(fix_html_tags "$1")
	tmp2=$(trim_rl "$tmp")
	tmp3=$(esc_s "$tmp2")
	echo $tmp3
}

show_capitulos(){
	#<a href="capitulo/
	for m in `grep '<a href="capitulo/' $1|grep -oe '[^"]*\.html'`; do
		echo $m
	done
}

get_frame(){
	##<embed type="application/x-shockwave-flash" src="
	for m in `grep '<embed type="application/x-shockwave-flash" src="' $1`; do
		echo $m
	done
}

## main
if (( ! $debug )); then
	bajaurl $url > $tmpfile
	makeutf8 $tmpfile
fi

#get title
#tit=$(gettitle $tmpfile)

#get trimmed title
titulo=$(trim_rl "$(gettitle $tmpfile)")
titulo=$(esc_fix_commas "$titulo")
titulo=$(fix_html_tags "$titulo")
titulo=$(fix_slash "$titulo")
titulo=$(fix_backslash "$titulo")

#agarra caratula
caratula=$(get_caratula_url $tmpfile)
if [[ "$caratula" = "" ]]; then caratula="$non_existing"; fi

tmp=$(get_sinopsis $tmpfile)
#echo $tmp
sinopsis=$(fix_sinopsis "$tmp")

#create some more variables

solonombre=$(trim_all "$titulo")
titulooriginal="$titulo"
generos_original="$generos"

# crea lista.$log de tvnovelas adicionadas
[[ -f lista.log ]] && :> lista.log || echo $capitulo_tit >>  lista.log

for capitulo in $(show_capitulos $tmpfile); do

	echo $baseurl$capitulo	
	capitulo_num=$(echo $capitulo|sed -e 's/capitulo\///g'|sed -e 's/.html//g')
	capitulo_tit=$(echo $capitulo_num|sed -e 's/-/ /g')

	#download capitulo
	if (( ! $debug )); then
		if [ -f $tmpfile.2 ]; then
			rm $tmpfile.2
		fi
		echo "bajando $baseurl$capitulo"
		bajaurl $baseurl$capitulo > $tmpfile.2
		makeutf8 $tmpfile.2
	fi

	#imprime status
	let reg++

	#for testing
	#if (( reg > 15 )); then exit; fi

  for tipo in {1..3}; do
	#clean frame variable
	frame=""
	notset=0
	case $tipo in
		1)
			#is normal
			sed -e '/div class="container/,/div style="clear:both/ !d'  $tmpfile.2 > 1.html

			#done, now fix ' and save
			frtmp=$(cat 1.html)
			frame=$(esc_s "$frtmp")

			#check if no frame data, then make it so it can skip
			if [[ $(trim_all "$frame") = "" ]];then 
				frame="" 
			else 
				frame="$frame</div>";
				gentmp="$generos_original, youtube, vk, dialymotion, video msn";
				generos="$gentmp"
			fi

			#remove files
			rm 1.html
			#if [[ "$frame" != "" ]]; then
			#	echo $frame
			#	read n
			#fi			
		;;
		2)
			##is vk
			for buildframe in `grep '<iframe src="http://vk.' $tmpfile.2 | grep -oe 'http://[^"]*'`; do
				frametmp=$(echo "<iframe src=\"$buildframe\" width=\"807\" height=\"360\" frameborder=\"0\"></iframe>")
				frametm2="$frame $frametmp"
				frame="$frametm2"
			done

			if [[ $(trim_all "$frame") = "" ]];then 
				frame=""
			else 
				frame="$frame";
				gentmp="$generos_original, vk";
				generos="$gentmp"
			fi

			
		;;
		3)
			#http://www.dailymotion.com
			for buildframe in `grep "http://www.dailymotion.com/embed/video/" $tmpfile.2 | grep -oe 'http://[^"]*'`; do
				frametmp=$(echo "<iframe src=\"$buildframe\" width=\"807\" height=\"360\" frameborder=\"0\"></iframe>")
				frametm2="$frame $frametmp"
				frame="$frametm2"
			done

			if [[ $(trim_all "$frame") = "" ]];then 
				frame=""
			else 
				frame="$frame";
				gentmp="$generos_original, dialymotion";
				generos="$gentmp"
			fi

		;;
		4)
	
			echo "never"
		;;
		# *)
		#	#metodo no allowed
		#	echo "metodo no definido!"
		#	frame=""
		#	exit 1
	esac

	#read n
	#save frame
	if [[ "$frame"  != "" ]]; then
		#not empty, add it!
		echo "************************************"
		echo "$capitulo_tit "
		echo $titulo
		echo $ano
		echo $sinopsis
		echo $caratula
		echo $solonombre
		echo $frame
		echo $generos
		echo "______________ $reg _______________________"
		echo ""

		echo "
INSERT INTO \`peliculas\` (\`titulo\`, \`nombre_caratula\`, \`titulo_original\`, \`ano\`, \`genero\`, \`sinopsis\`, \`imagen_url\`, \`frame_src\`, \`activo\`, \`reportado_roto\`, \`fecha_alta\`, \`fecha_reporte_roto\`, \`reporte_roto_email\`, \`reporte_roto_nombre\`, \`reporte_roto_comentario\`, \`fecha_ult_visita\`, \`numero_vistas\`, \`ult_visita_ip\`, \`comentarios\`) VALUES
('$capitulo_tit', '$solonombre', '$titulooriginal', '$ano', '$generos', '$sinopsis', '$caratula', '$frame', 1, 0, '$hoy', '$hoy', '', '', '', '$hoy', 0, '192.168.1.64', 'progna: $0 Ver. $version ($reg : $(date +%s)) $capitulo $caratula $(pwd) >> $out por Alex');
" >> $out
	
		#update mylog
		echo "$reg " >> $log
		notset=1

	else
		echo "brincando $reg"
		echo ""
	fi
   done	
	if (( notset )); then
		echo "Nota que no se encontro ningun frame para"
		echo "$capitulo"
		echo -n "pulsa enter?"
		#read n
		notset=0
	fi
done

#remove tmp files
rm $tmpfile $tmpfile.2

#end
echo "Listo! ->  $out"
  
echo "Fin!, aqui va el $log"
cat $log
