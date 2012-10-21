BAJAVIDEO
=========

scripts para bajar vídeos de sitios web 

La idea es poder hacer una serie de programas interconectables para descargar peliculas de servidores 
centralizados, convertirlos a formatos libres *(OGG principalmente)* y compartirlos en **torrent**, y/o 
**descargas directas** que no requieran usuario, clave o ningun tipo de restricción.

**Canal de IRC:** `irc://hackcoop.com.ar:6697/#lab` [web-irc](http://hackcoop.com.ar:8338/?channels=#lab)


Scrapear
--------

- **fullpeliculas:** Descarga todos los datos de las películas del sitio http://fullpeliculas.com
- **seriesyonkies:** Descarga todas las películas de http://www.seriesyonkis.com/ (No anda más)

Descargar
---------

- **vk:** descarga archivos con un enlace a vk.com
- **mu:** descarga archivos con un enlace a megaupload.com (no anda más)
- **bajanovela.sh:** Baja las novelas de http://vertelenovelas.net

Subir
-----

- **omploader:** script simple para subir archivos, capturas de pantalla y con la webcam a http://omploader.org
- **s3uploader.sh:** sube archivos a http://archive.org

Utilitarios
-----------

- **video2ogg:** convierte video en OGG
- **archivo2torrent:** crear un archivo torrent de un archivo

Carpetas
--------

- **data:** datos descargados
- **subtitles:** subtítulos de películas de cuevana

Quehaceres
----------

- Dividir scripts en pequeños módulos interconectables
- Automatizar/Demonizar descargas y subidas a sitios más copados
- Hacer scrapeador genérico :P

**Log en JSON:**

<pre>
callback({
        peliculas:[{
                titulo: "",
                descripcion: "",
                etiquetas: "",
                urls: ["http://...","http://..."]
        },{...}]
        novelas:[{}],
        series:[{}]
});
</pre>



Proyectos relacionados
----------------------

- [get-flash-videos](https://code.google.com/p/get-flash-videos/)
- [youtube-dl](http://rg3.github.com/youtube-dl/)
- [Plowshare](https://code.google.com/p/plowshare/)
