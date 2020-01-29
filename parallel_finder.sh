#!/bin/bash
#******************************************************************************************
#
# parallel_finder.sh
#
# Version: 1.00
#
# Script para realizar multiples busquedas de archivos en paralelo.
# Utiliza un archivo de entrada con el listado de archivos a buscar y luego
# genera otro archivo con todas las locaciones posibles de cada archivo encontrado.
#
# Desarrollado por: Damian Andres Ulanowicz
#
# -----------------------------------------------------------------------------------------
#
# Modo de uso:
# bash ./parallel_finder.sh input_list_file output_file [-w|--wait] [-h|--help]
#
#
# [-h|--help]          Ayuda.
#
# Ejemplo:   sh ./parallel_finder.sh input_list.txt sqr_locations.txt
#
#******************************************************************************************
LOG_PATH=./
LOG_FILE=parallel_finder.log

fg_term=0
home_path=$(pwd)
#export home_path=(`pwd`)
log_file=$home_path"/"$LOG_PATH$LOG_FILE
input_file=temp
output_file=temp2
wait_jobs=0
unset src_list


SIGTERM_Handler() 
{
   if [ $fg_rollback -eq 0 ]
   then
      fg_term=1

	  echo "proceso interrumpido"
      log_str=$(printf "[*] Proceso interrumpido.\n")
      echo_log "$log_str" "$log_file" 1 1

      cd $home_path
      end_log
   fi
   exit
}


show_banner()
{
   echo
   echo "********************************************************"
   echo "*                                                      *"
   echo "*                     parallel_finder.sh                    *"
   echo "*                     Version 1.00                     *"
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
   echo "bash ./parallel_finder.sh input_list_file output_file [-w|--wait] [-h|--help]"
   echo
   echo "[-h|--help]          Ayuda."
   echo
   echo "Ejemplo:"
   echo "sh ./parallel_finder.sh input_list.txt sqr_locations.txt"
   echo
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


parallel_finder()
{
   for ((i=0; i<$src_cnt; i++)); do    
      run_job ${src_list[${i}]} $1 &
      job_pid=$!
      echo "[+] Buscando: "${src_list[${i}]}" ... - PID: " $(($job_pid))
   done

   #jobs

   if [ $wait_jobs -eq 1 ]
   then
      wait
      echo "[*] Listo!"
   fi
}


run_job()
{
   find ./ -name $1 2> /dev/null | tee -a $2 | cat >/dev/null; printf "%s\n" "----------------------">>$2
}


read_args()
{
   input_file=$1
   output_file=$2

   numargs=$#
   if [ $numargs -lt 2 ];
   then
      echo "[-] Error: Parametros incorrectos"
      ayuda
      exit 2
   fi

   for ((i=1 ; i <= $numargs ; i++))
   do
      key="$1"
      case $key in
      -w|--wait)
         wait_jobs=1
         exit 1
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
   mkdir $home_path"/"$LOG_PATH 2>/dev/null
   log_str=""
   echo_log "$log_str" "$log_file" 1 0
   log_str="************************************************************"
   echo_log "$log_str" "$log_file" 1 0
   log_str="/////////////////////// parallel_finder.sh //////////////////////"
   echo_log "$log_str" "$log_file" 1 0
   log_str="////////////////////    Version 1.00    ////////////////////"
   echo_log "$log_str" "$log_file" 1 0
   log_str="------------------------------------------------------------"
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " Date  : %s" "$(date)")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " User  : %s" "$USER")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " Host  : %s" "$HOSTNAME")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf " Bash  : %s" "$BASH_VERSION")
   echo_log "$log_str" "$log_file" 1 0
   log_str="------------------------------------------------------------"
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf "src_list_file : %s" "$input_file")
   echo_log "$log_str" "$log_file" 1 0
   log_str=$(printf "output_file : %s" "$output_file")
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



trap SIGTERM_Handler INT TERM
show_banner
read_args $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15}

init_log
read_src $input_file

if [ $src_cnt -gt 0 ];
then
   parallel_finder $output_file &
else
   printf "[-] Error: El archivo: %s no contiene ningun entrada para buscar.\n" "$src_file" 1>&2
fi
end_log

unset src_list
trap - INT TERM
