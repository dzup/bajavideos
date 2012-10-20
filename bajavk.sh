#!/bin/bash
#
#       descarga videos de vk
#	por bazza en #lab lab.hackcoop.com.ar
#
#	16-oct-2012 at 19:22
#	modificado para multiples <iframes de $html
#	donde podrian existir mas de 1 <iframe src="...bk.com
#	por dzup	
# ej: ./vk http://u3mx.com/verpelicula.php?id=2

# necesitas offword.py
# aqui esta el src
#
#!/usr/bin/env python
#import sys
#s = sys.stdin.read()
#L = []
#for w in s.split():
#    if w not in L:
#        L.append(w)
#
#print " ".join(L)        


debug=1;
version="0.0.1b"
no_image_found="http://u3mx.com/images/imagen-no-existe.jpg"
sql_file_frame=frame-$(date -u +%F).sql
sql_file_pelicula=pelicula-$(date -u +%F).sql
logfile=$(date -u +%F).log
dirbackup=$(date -u +%F)/
# database general
id=""
titulo=""
url=""
url_download=""
sitio="vk"
fecha_alta=the-$(date -u +%F)
fecha_ultimo_movimiento=the-$(date -u +%F)
visitas=0
email="dzup@mailcatch.com"
password=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c 10 | xargs`
tipo_frame=0 ##publico
estatuto=1 ##activ
roto=0
comentarios="" 
pelicula_id=""

# descarga el contenido de laa pagina de embed

debug(){
	debug="$2"
	if (( debug )); then 
		echo "debug $1"
	fi
}

por_cada_vk_frame(){	
	for frame in $(echo "$1" | grep "<iframe src=\"http://vk.com/" | sed "s/^.*'\(.*\)'.*$/\1/g"); do
		echo "$frame"
	done
}

por_cada_vk_url(){
	echo "$1" | grep "http://vk.com/" | grep -oe 'http://[^"]*'
}


url_download_vk(){
	vk_html=$(wget "$1" -qO -)
	vtag=$(echo "$vk_html" | grep "vtag=" | sed 's/^.*vtag\=//g'|sed 's/&.*//'|uniq)
	uid=$(echo "$vk_html" | grep "var video_uid" | sed "s/^.*'\(.*\)'.*$/\1/g")
	host=$(echo "$vk_html" | grep "var video_host" | sed "s/^.*'\(.*\)'.*$/\1/g")
	video_title=$(echo "$vk_html" | grep "var video_title" | sed "s/^.*'\(.*\)'.*$/\1/g")
	echo "${host}u${uid}/video/${vtag}.360.mp4"
}

list_vk_url(){
	for vk_frame in $(por_cada_vk_frame "$1"); do
		for vk_url in $(por_cada_vk_url "$vk_frame"); do
			echo "$vk_url"
		done
	done
}

list_all_download_url(){
	for video_url in $(list_vk_url "$1"); do
		echo $(url_download_vk "$video_url")
	done
}

list_uniq_url(){
	echo $(list_all_download_url "$1"|uniq)
}

lowercase(){ echo "$1" | awk '{print tolower($0)}'; }

palabras_unicas(){ 
	#pas=$(echo "$1" | awk '{for(i=1;i<=NF;i++) a[$i]++} END{for(i in a) printf i" ";print ""}' )
	echo "$1" | ./offword.py
	#echo "$1"| sed 's/\ -.*$//g'
}

imprime_frase(){
	for i in $(echo "$1"); do
		frase="$frase $i"
	done
	echo "$frase"
}

quita_palabras(){
	paso1="$1"
	for palabra in {online,cine,latino,-,?}; do
		paso1=$(echo "$paso1" | sed 's/'$palabra'//g')
	done
	echo "$paso1"
}

gettitle(){
	tit=$(echo "$1" | grep "[<]title[>]" | sed -e "s/<title>//g"|sed -e "s/<\/title>//g"|sed 's/"//g'|sed -r "s/'/\\\'/g"|sed 's/<[^>]*>//g')
	titulo=$(echo "$tit"|sed -r "s/'/\\\'/g"|sed 's/ $//'|sed 's/ $//g'|sed 's/"/\\"/g'|sed 's/ $//'|sed 's/ $//g')
	echo "$titulo"
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

function sanatiza(){
	titulo=$(lowercase "$1")
	titulo=$(quita_palabras "$titulo")
	titulo=$(palabras_unicas "$titulo")
	titulo=$(imprime_frase "$titulo")
	titulo=$(ltrim "$titulo")
	titulo=$(rtrim "$titulo")
	titulo=$(esc_s "$titulo")
	#titulo=$(esc_d "$titulo")
	#titulo=$(fix_slash "$titulo")
	#titulo=$(fix_backslash "$titulo")
	#titulo=$(esc_fix_commas "$titulo")
	titulo=$(fix_html_tags "$titulo")
	echo "$titulo"
}
update_frame_pelicula_relation(){
	echo "UPDATE frame JOIN pelicula ON pelicula.titulo = frame.titulo SET frame.pelicula_id = pelicula.id WHERE pelicula.titulo = frame.titulo;" >> $sql_file_frame
}

adiciona_frame_sql(){
	echo "$2 $4"
	echo "INSERT INTO  \`a7850950_u3mx\`.\`frame\` (
\`id\`, \`titulo\` ,\`url\` ,\`url_download\` ,\`sitio\` ,\`fecha_alta\` ,\`fecha_ultimo_movimiento\` ,\`visitas\` ,\`email\` ,\`password\` ,\`tipo_frame\` ,\`estatuto\` ,\`roto\` ,\`comentarios\` ,\`pelicula_id\`) VALUES ('${2}',  '${3}',  '${4}',  '${5}',  '${6}',  '${7}',  '${8}',  '${9}',  '${10}',  '${11}',  '${12}',  '${13}',  '${14}',  '${15}',  '${16}');
" >> $sql_file_frame

}

adiciona_pelicula_sql(){
	echo "$2 $4"
	echo "INSERT INTO \`a7850950_u3mx\`.\`pelicula\` (\`id\`, \`titulo\`, \`titulo_original\`,
	 \`año\`, \`genero\`, \`sinopsis\`, \`caratula_url\`, \`TMBd_id\`, \`TMDb_imdb_id\`,
	  \`TMDb_original_title\`, \`TMDb_overview\`, \`TMDb_poster_path\`,
	   \`TMDb_production_companies_name\`, \`TMDb_production_countries_name\`, 
	   \`TMDb_release_date\`, \`TMDb_runtime\`, \`TMDb_status\`, \`TMDb_tagline\`, 
	   \`TMDb_title\`, \`TMDb_actors\`, \`TMDb_caratula_1\`, \`TMDb_caratula_2\`, 
	   \`TMDb_titulo_alternativo_1\`, \`TMDb_titulo_alternativo_2\`, \`TMDb_titulo_alternativo_3\`, 
	   \`TMDb_titulo_alternativo_4\`, \`numero_visitas\`, \`email\`, \`password\`,
	    \`comentarios\`, \`estatuto\`, \`adulto\`, \`fecha_alta\`, \`fecha_ultimo_mvto\`,
	     \`last_ip_1\`, \`last_ip_2\`, \`last_ip_3\`, \`last_ip_4\`, \`last_ip_5\`) 
	     VALUES ('${1}', '${2}', '${3}', '${4}', '${5}', '${6}', '${7}', '${8}', '${9}', 
	'${10}', '${11}', '${12}', '${13}', '${14}', '${15}', '${16}', '${17}', '${18}', 
	'${19}', '${20}', '${21}', '${22}', '${23}', '${24}', '${25}', '${26}', '${27}', 
	'${28}', '${29}', '${30}', '${31}', '${32}', '${33}', '${34}', '${35}', '${36}', 
	'${37}', '${38}', '${39}');" >> $sql_file_pelicula
}

get_caratula_url(){
# 1:cinevk.com
# 
	case $2 in ##cinevk.com guarda caratulas en veocine.tv
		1) caratula="http://veocine.tv/vk/"$(echo "$1"|sed -r 's/http:\/\/veocine.tv\/vk\///g'|sed -e 's/.jpg//g').jpg
		;;
	*) caratula="$no_image_found"
	esac
	echo "$caratula"
}

get_sinopsis(){
# 1:cinevk.com
# 
	case $2 in
		1) 
		sinopsis=$(echo "$1"|grep "Sinopsis"|sed 's/<[^>]*>//g'|sed -e 's/Sinopsis: //g')
	;;
		*)
		sinopsis=""
	;;
	esac
	echo "$sinopsis"
}

get_ano(){
# 1:cinevk.com
# 
	case $2 in
		1) 
		ano=$(echo "$1"|grep "Año:"|sed 's/<[^>]*>//g'|sed 's/Año: //g'|sed -r "s/'/\\\'/g"|sed 's/"//g'|sed 's/ $//'|sed 's/ $//g')
	;;
		*)
		ano=""
	;;
	esac
	echo "$ano"
}

ordena_alfabetica(){
	echo "$1"| tr , "\n" | sort | tr "\n" , | sed 's@\(.*\),@\1\n@'
}
get_genero(){
# 1:cinevk.com
# 
	case $2 in
		1) 
		generos="vk,"$(echo "$1"|grep "G*nero:"|sed 's/<[^>]*>//g'|sed -e 's/Género://g'|sed -r "s/'/\\\'/g"|sed 's/ $//')
	;;
		*)
		generos=""
	;;
	esac
	echo $(ordena_alfabetica "$generos")
}

## main

#echo $(muestra_enlace_descarga "$html" "pelicula titulo aqui")
# $1 variable.html
# $2 titulo pelicula
#
# limpia old data
:>$sql_file_frame
:>$sql_file_pelicula
:>$logfile
reg_pelicula=0
for i in {1..202}; do 
	url="http://cinevk.com/index.php?page=$i"
	#url="http://factsys.lo/u3mx.lo/u3mx.com/public_html/verpelicula.php?id="
	html=$(wget "$url" -qO -)

	#make sure only one caratula is get
	image_not_process="0"
	no_add="0"

	for m in $(echo "$html" | grep "http://veocine.tv/vk/" | grep -oe '[^"]*\.jpg'); do
		
		#calcula nombre html basado en jpg, segun es nombre-sin-jpg-extencion.html
		nombre_html_sin_jpg=$(echo $m|sed -r 's/http:\/\/veocine.tv\/vk\///g'|sed -e 's/.jpg//g')
		#pagina donde vive el iframe
		pagina_html_video="http://cinevk.com/$nombre_html_sin_jpg.html"

		frames=$(wget "$pagina_html_video" -qO -)
		frames=$(echo "$frames"|recode iso-8859-1..)
		titulo=$(gettitle "$frames")
		
		#### get my own info
		sinopsis=$(get_sinopsis "$frames" 1)
		ano=$(get_ano "$frames" 1)
		generos=$(get_genero "$frames" 1)
		#### end my own
		
		ano=$(sanatiza "$ano")
		titulo=$(sanatiza "$titulo")
		sinopsis=$(sanatiza "$sinopsis")
		generos=$(sanatiza "$generos")

		#mis generos son genero1,gen2,gen3  sin espacios, entonces quitalos
		generos=$(trim_all "$generos")
		genero="$generos"
		
		#adiciona pelicula sql		
		# '$id', '$titulo', '$titulo_original', '$año', '$genero', '$sinopsis', '$caratula_url', '$TMBd_id', '$TMDb_id', '$TMDb_original_title', '$TMDb_overview', '$TMDb_poster_path', '$TMDb_production_companies_name', '$TMDb_production_countries_name', '$TMDb_release_date', '60', '$TMDb_status', '$TMDb_tagline', '$TMDb_title', '$TMDb_actors', '$TMDb_caratula_1', '$TMDb_caratula_2', '$TMDb_titulo_alternativo_1', '$TMDb_titulo_alternativo_2', '$TMDb_titulo_alternativo_3', '$TMDb_titulo_alternativo_4', '0', '$email', '$password', '$comentarios', '$estatuto', '$adulto', '', '', '$last_ip_1', '$last_ip_2', '$last_ip_3', '$last_ip_3', '$last_ip_3')
		let reg_pelicula++
		comentarios_pelicula="$0 $version[$(whoami)@$(hostname):$(uname -nrmp)] $reg_pelicula:$(date +%s) $sql_file_pelicula >> $url"
		adiciona_pelicula_sql "" "$titulo" "$titulo_original" "$ano" "$genero" "$sinopsis" "$caratula_url" "$TMBd_id" "$TMDb_id" "$TMDb_original_title" "$TMDb_overview" "$TMDb_poster_path" "$TMDb_production_companies_name" "$TMDb_production_countries_name" "$TMDb_release_date" "$TMDb_runtime" "$TMDb_status" "$TMDb_tagline" "$TMDb_title" "$TMDb_actors" "$TMDb_caratula_1" "$TMDb_caratula_2" "$TMDb_titulo_alternativo_1" "$TMDb_titulo_alternativo_2" "$TMDb_titulo_alternativo_3" "$TMDb_titulo_alternativo_4" "0" "$email" "$password" "$comentarios_pelicula" "$estatuto" "$adulto" "$fecha_alta" "$fecha_ultimo_movimiento" "$last_ip_1" "$last_ip_2" "$last_ip_3" "$last_ip_3" "$last_ip_3"
		echo "" >> $logfile
		echo "$reg_pelicula $titulo $ano" >>  $logfile
		echo "$sinopsis" >> $logfile
		echo "$comentarios_pelicula" >> $logfile
		#echo "" >> $logfile 

		#make sure only grab 1 caratula per item
		if (( ! image_not_process )); then
			image_not_process="1"
		else
			caratula_url=$(get_caratula_url "$m" 1) 
			image_not_process="0"
		fi		
		for frame in $(por_cada_vk_frame "$frames"); do
			for url in $(por_cada_vk_url "$frame"); do
				url_download=$(url_download_vk "$url")
				let reg++
				comentarios_frame="$0 $version[$(whoami)@$(hostname):$(uname -nrmp)] $reg:$(date +%s) $sql_file_frame >> $url"
				adiciona_frame_sql "$sql_file_frame" "$id" "$titulo" "$url" "$url_download" "$sitio" "$fecha_alta" "$fecha_ultimo_movimiento" "$visitas" "$email" "$password" "$tipo_frame" "$estatuto" "$roto" "$comentarios_frame" "$pelicula_id"
				#echo "$reg $titulo" >> $logfile
				echo " $reg $url" >> $logfile
				echo " $reg $url_download" >> $logfile
				echo " $comentario_frame" >> $logfile
				#echo "" >> $logfile 
			done
		done
	done
done
mkdir -p $dirbackup
cp $sql_file_frame $dirbackup$sql_file_frame
cp $sql_file_pelicula $dirbackup$sql_file_pelicula

echo "Listo, ahora instrucciones:
cd $dirbackup
mysql -u user -p

use use database;
source $sql_file_frame;
source $sql_file_pelicula;
UPDATE frame JOIN pelicula ON pelicula.titulo = frame.titulo SET frame.pelicula_id = pelicula.id WHERE pelicula.titulo = frame.titulo;
exit;

mysqldump -u [username] -p [password] [databasename] > [backupfile.sql]
Read more at http://www.devshed.com/c/a/MySQL/Backing-up-and-restoring-your-MySQL-Database/#gfokSs5vas2xYOq5.99

Ahora esta todo listo, bajate la tabla unica a un sqp.zip y subela al servidor.

"
