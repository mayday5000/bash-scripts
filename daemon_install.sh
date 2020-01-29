#! /bin/sh
# ./install.sh
#

PARAM=$1
FLAG_OK=0
DAEMON_NAME='comd'
DAEMON_FILE='./comd'
DAEMON_SCRIPT='./comd.sh'
CONFIG_PATH='/etc/comd'
LOG_PATH='/var/log/comd'
CONFIG_FILE_1='./net_config'
CONFIG_FILE_2='./db_config'


if [ `whoami` != root ]; then
	echo "Es necesario ejecutar este script como usuario root!" 1>&2
	exit
else
	if ps -eo euser,ruser,suser,fuser,f,comm,label | grep -v grep | grep $DAEMON_NAME > /dev/null
	then
		echo "--> Deteniendo servicio $DAEMON_NAME..."
		pkill $DAEMON_NAME
		if test $? -ne 0 
		then
			echo "No se pudo terminar el proceso $DAEMON_NAME"
		fi
	fi

	echo "--> Copiando archivos necesarios..."
	cp $DAEMON_FILE /usr/sbin
	cp $DAEMON_SCRIPT /etc/init.d/$DAEMON_NAME
	chmod +x /etc/init.d/$DAEMON_NAME
	if [ ! -d $CONFIG_PATH ]; then
		mkdir $CONFIG_PATH
	fi
	cp $CONFIG_FILE_1 $CONFIG_PATH
	cp $CONFIG_FILE_2 $CONFIG_PATH
	if [ ! -d $LOG_PATH ]; then
		mkdir $LOG_PATH
	fi
	if test $? -ne 0 
	then
		echo " * El servicio $DAEMON_NAME no se instalo correctamente." 1>&2
		exit 1
	fi



	if ls /etc/rc2.d/ |grep $DAEMON_NAME  > /dev/null
	then
		echo "--> Removiendo servicio $DAEMON_NAME..."
		update-rc.d -f $DAEMON_NAME remove	
	fi

	echo "--> Instalando servicio $DAEMON_NAME..."
	update-rc.d $DAEMON_NAME defaults

	if ls /etc/rc2.d/ |grep $DAEMON_NAME  > /dev/null
	then
		echo " * El servicio $DAEMON_NAME se instalo con exito!"
		FLAG_OK=1
	else
		echo "Hubo un problema en la instalacion del servicio."
		echo "--> Removiendo servicio $DAEMON_NAME..."
		update-rc.d -f $DAEMON_NAME remove	
		echo "--> Instalando servicio $DAEMON_NAME..."
		update-rc.d $DAEMON_NAME defaults
		if ls /etc/rc2.d/ |grep $DAEMON_NAME  > /dev/null
		then
			echo " * El servicio $DAEMON_NAME se instalo con exito!"
			FLAG_OK=1
		else
			echo " * El servicio $DAEMON_NAME no se instalo correctamente." 1>&2
			exit 1
		fi
	fi

	case $PARAM in
	  start)
		    echo "--> Iniciando servicio $DAEMON_NAME..."
		    /etc/init.d/$DAEMON_NAME start			
		    ;;
	  stop)
		    echo "--> Deteniendo servicio $DAEMON_NAME..."
		    /etc/init.d/$DAEMON_NAME stop			
		    ;;
	  restart)
		    echo "--> Reiniciando servicio $DAEMON_NAME..."
		    /etc/init.d/$DAEMON_NAME restart			
		    ;;
	  *)
		    if test $FLAG_OK -eq 1
		    then
			echo
			echo "Edite los archivos de configuracion ubicados en el path $CONFIG_PATH antes de iniciar el servicio."		    
		        echo "/etc/init.d/$DAEMON_NAME {start|stop|restart} para controlar el servicio."
		    fi
		    ;;
	esac
fi

exit 0


