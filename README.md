#******************************************************************************************
#
# pattern_replace.sh
#
# Version: 1.30
#
# Script que permite reemplazar un patron de texto determinado dentro de varios archivos de texto.
# Desarrollado por: Damian Andres Ulanowicz
#
# Modo de uso:
# sh ./pattern_replace.sh -e -i [-o] -s -d [-r] [-h]
#
# -e|--extension       Extensiones de los archivos a procesar, separados por coma.
# -i|--inputpath       Ruta de archivos a procesar.
# [-o|--outputpath]    Ruta de archivos procesados. Default: ./Output
# -s|--srcpattern      Archivo con lineas de texto a buscar en los archivos fuente.
# -d|--dstpattern      Archivo con lineas de texto a reemplazar en los archivos fuente.
#                      Cada linea en srcpattern sera reemplazada por la correspondiente 
#                      linea de dstpattern en los archivos fuente.
# [-r|--recursive]     Opcion de recursividad, (para procesar archivos en los subdirectorios).
# [-h|--help]          Ayuda.
#
# Ejemplo:   sh ./pattern_replace.sh -e htm,xml,html,php,cgi,pl -i ./Input -o ./Output -s ./Pattern_replace/pattern_src.txt -d ./Pattern_replace/pattern_dst.txt -r
#
#******************************************************************************************