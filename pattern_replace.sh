#!/bin/bash
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

PATTERN_PATH=./Pattern_replace/
PATTERN_EXT=*.*
#INPUT_PATH=./Input/
#INPUT_EXT=*.*
OUTPUT_PATH=./Output/
UP_PATH=.
LOG_PATH=/Log/
LOG_FILE=pattern_replace.log
TMP1_EXT=.tmp1
TMP2_EXT=.tmp2
MAX_SED_STR=2000         # Longitud maxima de string a procesar por el comando sed.
                         # Este parametro es variable, y depende de la version, y del ABI.

fg_error=0
fg_rollback=0
fg_critical=0
pattern_cnt=0
recursive=0
process_cnt=0
error_cnt=0
home_path=$(pwd)
log_file=$home_path$LOG_PATH$LOG_FILE
unset pattern_list
unset ext_list
unset src_list
unset dst_list
unset sed_cat_list


rollback() 
{
   if [ $fg_rollback -eq 0 ]
   then
      fg_rollback=1

      if [ $fg_critical -eq 1 ]
      then
         log_str=$(printf "[*] Proceso interrumpido: Rollback...\n")
         echo_log "$log_str" "$log_file" 1 1
         if [ -f "$input_file$TMP1_EXT" ]
         then
            rm -f $input_file$TMP1_EXT 2>/dev/null
         fi
         if [ -f "$input_file$TMP2_EXT" ]
         then
            rm -f $input_file$TMP2_EXT 2>/dev/null
         fi
      else
         log_str=$(printf "[*] Proceso interrumpido.\n")
         echo_log "$log_str" "$log_file" 1 1
      fi

      cd $home_path
      end_log
   fi
   exit
}


read_src()
{
   local src_file=$1
   local line=""
   src_cnt=0

   while IFS= read -r line
   do
      src_list[${src_cnt}]=$(printf '%s\n' "$line")
      src_cnt=$((src_cnt+1))
   done <"$src_file"
}


read_dst()
{
   local dst_file=$1
   local line=""
   dst_cnt=0

   while IFS= read -r line
   do
      dst_list[${dst_cnt}]=$(printf '%s\n' "$line")
      dst_cnt=$((dst_cnt+1))
      if [ $dst_cnt -eq $src_cnt ]
      then
         break
      fi
   done <"$dst_file"
}


load_pattern()
{
   for pattern_file in $PATTERN_PATH$PATTERN_EXT
   do
      if [ -f "$pattern_file" ]
      then
         pattern=$(cat $pattern_file)
         pattern_list[${pattern_cnt}]=$pattern
         pattern_cnt=$((pattern_cnt+1))
      fi
   done
}


load_ext()
{
   local aux1=$1
   ext_len=${#aux1}
   ext_cnt=0
   end=1

   while [ "$end" -gt 0 ]
   do
      end=`expr index "$aux1" ,`
      if [ "$end" -gt 0 ]
      then
         aux2=${aux1:0:end-1}
         aux1=${aux1:end:ext_len-end}
      else
         aux2=${aux1:0:ext_len-end}
      fi
      ext_list[${ext_cnt}]=$aux2
      ext_cnt=$((ext_cnt+1))
   done
}


verify_ext()
{
   local file_name=$1
   ret=$2

   ret=0
   file_ext=$(echo $file_name | awk -F "." '{print $NF}')

   for ((i=0; i<$ext_cnt; i++)); do    
      ext=${ext_list[${i}]}
      if [ "$file_ext" = "$ext" ]
      then
         ret=1
         break
      fi
   done
   return $ret
}


build_sed_cat()
{
   local aux=""
   pass_count=$1
   pass_count=0
   fg_cat=0
   delim=$(printf '\001')

   for ((i=0; i<$src_cnt; i++)); do    
      src_pattern=${src_list[${i}]}

      if [[ ! $src_pattern = "" ]]
      then
         if [ $i -lt $dst_cnt ]
         then
            dst_pattern=${dst_list[${i}]}
         else
            dst_pattern=""
         fi
         
         if [[ $fg_cat -eq 0 ]]
         then
            str_cat="s"
         else
            str_cat=$str_cat";s"
         fi

         fg_cat=1            
         str_cat=$str_cat$delim$src_pattern$delim$dst_pattern$delim"g"
         str_len=${#str_cat}

echo "i: $i"
echo "str_len: $str_len"

         if [[ "$str_len" -gt "$MAX_SED_STR" ]]
         then
            rev_pos=$(echo $str_cat|awk '{for(i=length;i!=0;i--)x=x substr($0,i,1);}END{str=";s'$delim'";pos=index(x,str);print pos;}')
            pos=$((str_len-rev_pos))

            if [[ "$pos" -lt 5 ]]
            then
               echo "[-] Error: El string #:$i a reemplazar no puede exceder "$(($MAX_SED_STR-5))" bytes."
               exit 2
            fi

            fg_cat=0
            aux=$str_cat
            str_cat=${str_cat:0:pos}
            sed_cat_list[${pass_count}]=$str_cat
            pass_count=$((pass_count+1))


echo $str_cat
echo "pass_count: $pass_count"


            str_cat=${aux:pos+3:str_len-1}
         fi
      fi
   done

   str_len=${#str_cat}
   if [[ "$str_len" -gt 0 ]]
   then
      sed_cat_list[${pass_count}]=$str_cat
      pass_count=$((pass_count+1))
echo $str_cat
echo "pass_count: $pass_count"
   fi

   return $pass_count
}


process_files()
{
   local current_path=$1
   local mask="/*"
   log_str="[+] Directorio actual: $current_path"
   echo_log "$log_str" "$log_file" 1 1

   for input_file in $current_path$mask
   do
      fg_error=0

	if [ ! -d "$input_file" ]
      then
         if [ -f "$input_file" ]
         then
            fg_critical=1
            cp -f $input_file $input_file$TMP1_EXT

            verify_ext $input_file $valid
            valid=$?
            if [ $valid -eq 1 ];
            then
               log_str=$(printf "[*] Procesando: %s\n" "$input_file")
               echo_log "$log_str" "$log_file" 1 1

               for ((i=0; i<$src_cnt; i++)); do    
                  src_pattern=${src_list[${i}]}

                  if [[ ! $src_pattern = "" ]]
                  then
                     if [ $i -lt $dst_cnt ]
                     then
                        dst_pattern=${dst_list[${i}]}
                     else
                        dst_pattern=""
                     fi
                     
                     if [[ $i -eq 0 ]]
                     then
                        str_cat="s"
                     else
                        str_cat=$str_cat";s"
                     fi

                     str_cat=$str_cat$delim$src_pattern$delim$dst_pattern$delim"g"


                     if ! sed -e $str_cat "$input_file""$TMP1_EXT" > "$input_file""$TMP2_EXT"
                     then
                        log_str=$(printf "[-] Error al correr el comando sed en el archivo: %s\n" "$input_file") 1>&2
                        echo_log "$log_str" "$log_file" 1 1
                        fg_error=1
                     else
                        if ! mv -f $input_file$TMP2_EXT $input_file$TMP1_EXT 2>/dev/null
                        then
                           log_str=$(printf "[-] Error al mover el archivo: %s\n" "$input_file""$TMP2_EXT") 1>&2
                           echo_log "$log_str" "$log_file" 1 1
                           fg_error=1
                        fi
                     fi
                  fi
               done
            fi
            fg_critical=0

            if [ $fg_error -eq 0 ]
            then
               if ! mv -f $input_file$TMP1_EXT $OUTPUT_PATH$input_file 1>&2
               then
                  log_str=$(printf "[-] Error al mover el archivo: %s\n" "$input_file""$TMP1_EXT") 1>&2
                  echo_log "$log_str" "$log_file" 1 1
                  rm -f $input_file$TMP1_EXT 2>/dev/null
                  error_cnt=$((error_cnt+1))
               else
                  if [ $valid -eq 1 ];
                  then
                     log_str=$(printf "[+] OK\n")
                     echo_log "$log_str" "$log_file" 1 1
                     process_cnt=$((process_cnt+1))
                  fi
               fi
            else
               rm -f $input_file$TMP1_EXT 2>/dev/null
               rm -f $input_file$TMP2_EXT 2>/dev/null
               error_cnt=$((error_cnt+1))
            fi
         fi
      else
         if [ $recursive -eq 1 ]
         then
            mkdir $OUTPUT_PATH$input_file 2>/dev/null
            if [ ! -d "$OUTPUT_PATH$input_file" ]
            then
               log_str=$(printf "[-] Error: No se pudo crear directorio: %s\n" "$OUTPUT_PATH$input_file") 1>&2
               echo_log "$log_str" "$log_file" 1 1
               error_cnt=$((error_cnt+1))
            else
               process_files $input_file
            fi
         fi
      fi

   done

}


show_banner()
{
   echo
   echo "********************************************************"
   echo "*                                                      *"
   echo "*                  pattern_replace.sh                  *"
   echo "*                     Version 1.30                     *"
   echo "*                                                      *"
   echo "* Desarrollado por: Damian Andres Ulanowicz            *"
   echo "*                                                      *"
   echo "********************************************************"
   echo
}


ayuda()
{
   echo 
   echo "Ayuda:"
   echo
   echo "sh ./pattern_replace.sh -e -i [-o] -s -d [-r] [-h]"
   echo
   echo "-e|--extension       Extensiones de los archivos a procesar, separados por coma."
   echo "-i|--inputpath       Ruta de archivos a procesar."
   echo "[-o|--outputpath]    Ruta de archivos procesados. Default: ./Output"
   echo "-s|--srcpattern      Archivo con lineas de texto a buscar en los archivos fuente."
   echo "-d|--dstpattern      Archivo con lineas de texto a reemplazar en los archivos fuente." 
   echo "                     Cada linea en srcpattern sera reemplazada por la correspondiente "
   echo "                     linea de dstpattern en los archivos fuente."
   echo "[-r|--recursive]     Opcion de recursividad, (para procesar archivos en los subdirectorios)."
   echo "[-h|--help]          Ayuda."
   echo
   echo "Ejemplo:   sh ./pattern_replace.sh -e htm,xml,html,php,cgi,pl -i ./Input -o ./Output -s ./Pattern_replace/pattern_src.txt -d ./Pattern_replace/pattern_dst.txt -r"
   echo
}


echo_log()
{
   local str=$1
   local f_name=$2
   local fg_newline=$3
   local fg_stdout=$4

   if [ $fg_newline -eq 1 ]
   then
      printf "%s\n" "$str" >>$f_name
      if [ $fg_stdout -eq 1 ]
      then
         printf "%s\n" "$str"
      fi
   else
      printf "%s" "$str" >>$f_name
      if [ $fg_stdout -eq 1 ]
      then
         printf "%s" "$str"
      fi
   fi
}


init_log()
{
   mkdir $home_path$LOG_PATH 2>/dev/null
   log_str=""
   echo_log "$log_str" "$log_file" 1 0
   log_str="************************************************************"
   echo_log "$log_str" "$log_file" 1 0
   log_str="//////////////////// pattern_replace.sh ////////////////////"
   echo_log "$log_str" "$log_file" 1 0
   log_str="////////////////////    Version 1.30    ////////////////////"
   echo_log "$log_str" "$log_file" 1 0
   log_str="------------------------------------------------------------"
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " Inicio: %s" "$(date)")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " User  : %s" "$USERNAME")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " Host  : %s" "$HOSTNAME")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " Bash  : %s" "$BASH_VERSION")
   echo_log "$log_str" "$log_file" 1 0
   log_str="------------------------------------------------------------"
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " --extension  : %s" "$ext_arg")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " --inputpath  : %s" "$INPUT_PATH")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " --outputpath : %s" "$OUTPUT_PATH")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " --srcpattern : %s" "$src_pattern")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " --dstpattern : %s" "$dst_pattern")
   echo_log "$log_str" "$log_file" 1 0
   if [ $recursive -eq 1 ]
   then
      aux_str="Si"
   else
      aux_str="No"
   fi
   log_str=$(printf " --recursive  : %s" "$aux_str")
   echo_log "$log_str" "$log_file" 1 0
   log_str="------------------------------------------------------------"
   echo_log "$log_str" "$log_file" 1 0
}


end_log()
{
   log_str="------------------------------------------------------------"
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " Fin: %s" "$(date)")
   echo_log "$log_str" "$log_file" 1 0
   log_str="------------------------------------------------------------"
   echo_log "$log_str" "$log_file" 1 0
   log_str="************************************************************"
   echo_log "$log_str" "$log_file" 1 0
}


read_args()
{
   numargs=$#
   if [ $numargs -lt 1 ];
   then
      echo "[-] Error: Parametros incorrectos"
      ayuda
      exit 2
   fi

   fg_extension=0
   fg_srcpattern=0
   fg_dstpattern=0
   fg_inputpath=0
   for ((i=1 ; i <= $numargs ; i++))
   do
      key="$1"
      case $key in
      -e|--extension)
         ext_arg="$2"
         fg_extension=1
         shift
         ;;
      -i|--inputpath)
         INPUT_PATH="$2"
         fg_inputpath=1
         shift
         ;;
      -o|--outputpath)
         OUTPUT_PATH="$2"
         shift
         ;;
      -s|--srcpattern)
         src_pattern="$2"
         fg_srcpattern=1
         shift
         ;;
      -d|--dstpattern)
         dst_pattern="$2"
         fg_dstpattern=1
         shift
         ;;
      -r|--recursive)
         recursive=1
         shift
         ;;
      -h|--help)
         ayuda
         exit 1
         ;;
      *)      # Opcion desconocida, avanzar...
         shift  
         ;;
      esac
   done

   if [ $fg_extension -eq 0 -o $fg_srcpattern -eq 0 -o $fg_dstpattern -eq 0 -o $fg_inputpath -eq 0 ]
   then
      ayuda
      exit 2
   fi
}


valid_args()
{
   if [[ "$ext_arg" = *"/"* ]]
   then
      echo "[-] Error en parametro -e|--extension."
      ayuda
      exit 2
   fi

   if [[ "$ext_arg" = *"-"* ]]
   then
      echo "[-] Error en parametro -e|--extension."
      ayuda
      exit 2
   fi

   if [ ! -f "$src_pattern" ]
   then
      echo "[-] Error: archivo srcpattern no existe."
      ayuda
      exit 2
   fi

   if [ ! -f "$dst_pattern" ]
   then
      echo "[-] Error: archivo dstpattern no existe."
      ayuda
      exit 2
   fi

   fin="${INPUT_PATH: -1}"
   if [[ ! "$fin" = "/" ]]
   then
      INPUT_PATH="$INPUT_PATH""/"
   fi

#  Se omite "~" porque es reemplazado por $(pwd)
   if [[ ${INPUT_PATH:0:1} != "/" ]]
   then
      INPUT_PATH=$home_path"/"$INPUT_PATH
   fi

   if [ ! -d "$INPUT_PATH" ]
   then
      echo "[-] Error: Ruta input no existe."
      ayuda
      exit 2
   fi

   fin="${OUTPUT_PATH: -1}"
   if [[ ! "$fin" = "/" ]]
   then
      OUTPUT_PATH="$OUTPUT_PATH""/"
   fi

#  Se omite "~" porque es reemplazado por $(pwd)
   if [[ ${OUTPUT_PATH:0:1} != "/" ]]
   then
      OUTPUT_PATH=$home_path"/"$OUTPUT_PATH
   fi

   mkdir $OUTPUT_PATH 2>/dev/null	# Intenta crear directorio por si no existe, tomando el default.
   if [ ! -d "$OUTPUT_PATH" ]
   then
      echo "[-] Error: Ruta output no existe."
      ayuda
      exit 2
   fi
}


trap rollback INT TERM
show_banner
read_args $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15}
valid_args
init_log
read_src $src_pattern
read_dst $dst_pattern
load_ext $ext_arg
#load_pattern
if [ $src_cnt -gt 0 ];
then
   build_sed_cat $pass
   pass=$?

   echo "pass= $pass"
   for ((i=0; i<$pass; i++)); do    
      sed_str=${sed_cat_list[${i}]}
      echo "sed_str [$i]: $sed_str"
      echo
   done

   exit


   cd $INPUT_PATH
   current_path="."
   process_files $current_path

   echo_log "" "$log_file" 1 1
   log_str="[+] $error_cnt Errores."
   echo_log "$log_str" "$log_file" 1 1
   log_str="[+] $process_cnt Archivos procesados."
   echo_log "$log_str" "$log_file" 1 1
   echo_log "" "$log_file" 1 1
   cd $home_path
else
   printf "[-] Error: No se encontro ningun patron de busqueda en el archivo: %s\n" "$src_pattern" 1>&2
fi
end_log

unset pattern_list
unset ext_list
unset src_list
unset dst_list
trap - INT TERM



