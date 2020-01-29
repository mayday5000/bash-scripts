#! /bin/sh
# ./read.sh
#

# Autor: Damian Ulanowicz.
# Descripción: Script que permite crear usuarios de MySQL con sus respectivos permisos.
#
#


SERVER_HOST=192.168.0.49
SERVER_USER=root
CLIENT_HOST=192.168.0.49
CLIENT_USER=linux_admin
PATH1=/dev/shm/
PATH2=~/
LOG=/tmp/batch_create_user.log


read_password()
{
	fg_retry_pass=1
	while [ $fg_retry_pass -eq 1 ]; 
	do
		printf "Ingrese el password del usuario "$CLIENT_USER"@"$CLIENT_HOST": "
		stty -echo
		read pass
		stty echo
		printf '\n'

		printf "Verifique el password del usuario "$CLIENT_USER"@"$CLIENT_HOST": "
		stty -echo
		read pass2
		stty echo
		printf '\n'

		if [ "$pass" != "$pass2" ] 
		then 
			echo "Verificacion incorrecta!\n"
		else 	
			fg_retry_pass=0
		fi
	done
	if [ "$pass" = "" ]
	then
		echo "Error: El password no puede estar vacio!\n"
		exit 1
	fi
}


check_path()
{
	if [ ! -w "$PATH1" ]
	then
		PATH1=$PATH2
		if [ ! -w "$PATH1" ]
		then
			if [ -d "$PATH1" ]
			then
				if [ `whoami` != root ]; then
					echo "Permiso denegado. Ejecute este script como usuario root!" 1>&2
				else
					printf "Error: No es posible escribir en el directorio: %s\n" "$PATH1" 1>&2
				fi
			else
				printf "Error: No existe el directorio: %s\n" "$PATH1" 1>&2
			fi
			exit 1
		fi
	fi
}


create_random_filename()
{
	r_num=$(echo |awk '{print int(1 + rand() * 100000)}') 2>/dev/null
	FILE=$PATH1$r_num$(date +%Y%m%d%H%M%S)
}


create_script()
{
	if ! touch $FILE 2>/dev/null
	then
		printf "Error: No se puede escribir archivo: %s\n" "$FILE" 1>&2
		exit 1
	fi

	printf "CREATE USER '%s'@'%s' IDENTIFIED BY '***';\n" "$CLIENT_USER" "$CLIENT_HOST" > $FILE
	printf "GRANT ALL PRIVILEGES ON * . * TO '%s'@'%s' IDENTIFIED BY '***' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 	MAX_CONNECTIONS_PER_HOUR 0 ;\n" "$CLIENT_USER" "$CLIENT_HOST" >> $FILE
	printf "SET PASSWORD FOR '%s'@'%s' = PASSWORD( '%s' );\n" "$CLIENT_USER" "$CLIENT_HOST" "$pass" >> $FILE
	printf "GRANT ALL PRIVILEGES ON \`%s\_%%\` . * TO '%s'@'%s';\n" "$CLIENT_USER" "$CLIENT_USER" "$CLIENT_HOST" >> $FILE
	printf "FLUSH PRIVILEGES;\n" >> $FILE
}


run_script()
{
	echo
	printf "Login Server: "$SERVER_USER"@"$SERVER_HOST"\n"
	if mysql -h $SERVER_HOST -u $SERVER_USER -p -f -vvv <$FILE 1>/dev/null
	then
		echo
		echo "* El usuario se creó con éxito!"
	else
		echo
		echo "* Se produjo un error al crear el usuario!" 1>&2
	fi
	echo
}


delete_script()
{
	rm $FILE 2>/dev/null
}



ayuda () 
{
        (
        echo "Uso: $0 -s server-host -u server-user -c client-host -l client-user -p privileges [-d database]  " 
	echo
        echo "  -s server-host  Nombre del host o la direccion ip del servidor MySQL el cual se le asignara los privilegios al nuevo usuario."
	echo "  -u server-user  Nombre del usuario del servidor MySQL al cual se desea conectar para crear el nuevo usuario."
	echo "  -c client-host  Nombre del host o la direccion ip desde el cual el nuevo usuario podra conectarse al servidor."
	echo "  -l client-user  Nombre del nuevo usuario a crear."
	echo "  -p privileges   Determina que privilegios tendra el nuevo usuario."
	echo "                  Se podran especificar las siguientes opciones:"
	echo "                  [Adm] - Perfil de usuario Administrador (control total)."
	echo "                  [App] - Perfil de usuario para una aplicacion (Solo se abilitaran los permisos de acceso a datos. Las tareas de administracion, y las modificaciones en la estructura de las bases de datos no estaran permitidas)."
	echo "  [-d database]   Especifica el nombre de la base de datos a la cual el usuario tendra permisos de acceso. En caso de no utilizar esta opcion el usuario tendra permisos para todas las bases de datos del servidor."

        echo "  -h              Muestra esta ayuda."
        echo ""
        ) 1>&2
        exit 2
}


set +e
args=`getopt suclp:dh $*`
if [ $? -ne 0 ] ; then
        ayuda
        exit 2
fi
set -e

set -- $args
SHARED_WITH_HOST=false
for i
do
        case "$i" 
        in
        -s)
                SERVER_HOST=$2
                shift
#                shift
                ;;
        -u)
                SERVER_USER="$2"
                shift
#                shift
                ;;
        -c)
		shift
                CLIENT_HOST="$1"
                shift
#                shift
                ;;
        -l)
                CLIENT_USER="$1"
                shift
                shift
                ;;
        -h)
                ayuda
		shift
                ;;

        --)
                shift
                break
        esac
done

echo $SERVER_HOST
echo $SERVER_USER
echo $CLIENT_HOST
echo $CLIENT_USER


usage () 
{
        (
        echo "Usage: $0 [-s] -i FreeNAS-full.img" 
        echo "  -i filename     FreeNAS file image path"
        echo "  -s              Enable a shared LAN with Qemu host"
        echo "  -h              Display this help"
        echo ""
        ) 1>&2
#        exit 2
}



#if [ $# -lt 0 ]
#then
#	echo "Cantidad de parámetros incorrecto." 1>&2
#	echo "Sintaxis: $0 [Server_Host] [Server_User] [Client_Host] [Client_User] [Privileges]"
#	echo 
#	echo "[Server_Host]   Esta opcion especifica el nombre del host o la direccion ip del Servidor MySQL el cual se le asignara #los privilegios al nuevo usuario."
#	echo 
#	echo "[Server_User]   Indica el nombre del usuario del Servidor MySQL al cual se desea conectar para crear el nuevo usuario."
#	echo 
#	echo "[Client_Host]   Esta opcion especifica el nombre del host o la direccion ip desde el cual el nuevo usuario podra #conectarse al servidor."
#	echo 
#	echo "[Client_User]   Indica el nombre del nuevo usuario a crear."
#	echo 
#	echo "[Privileges]   Determina que privilegios tendra el nuevo usuario."
#	echo "               Se podran especificar las siguientes opciones:"
#	echo "               Adm - Perfil de usuario Administrador (control total)."
#	echo "               App - Perfil de usuario para una aplicacion (Solo se abilitaran los permisos de acceso a datos. Las #tareas de administracion, y las modificaciones en la estructura de las bases de datos no estaran permitidas)."
#	exit 1
#fi

# -h -u -c -n 


read_password
check_path
create_random_filename
create_script
run_script
delete_script


#  GRANT ALL PRIVILEGES ON `DY\_Caja`.* TO 'prueba'@'192.168.0.49' WITH GRANT OPTION;



