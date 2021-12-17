#!/bin/ksh

### Script para enviar ficheros a multiples maquinas, creado en un rato libre, necesita pulirse y añadir funcionalidades
### 0.2
### Daniel Molina

#set -x
#exec > /var/tmp/$$ 2>&1


SCP=/usr/bin/scp


print_uso()
{
		echo "Este script sirve para enviar un fichero a multiples máquinas"
        echo "Uso: "
        echo "Este script necesita parámetros para funcionar"
        echo "-h para mostrar la ayuda"
        echo "-f para pasar el fichero a enviar. NECESARIO"
        echo "-M fichero con la lista de maquinas a las que se quiere enviar. NECESARIO"
        echo "-P password de TODAS las maquinas, OJO!! si el fichero de maquinas tiene una passwod en una maquina priorizara la password del fichero, OJITO!! usa el comando sshpass"
        echo "-p path completo donde dejar el fichero, sin este parametro dejara el fichero en el /home del usuario, asegurate de tener permiso de escritura en el directorio"
        echo "-u usuario, por defecto cogera el usuario con el que te has logeado en la maquina desde donde ejecutas este script"
        echo "El fichero de maquinas puede contener las password de cada una separadas por un espacio despues de su respectiva maquina"
        echo "El fichero de maquinas puede contener el usuario de cada maquina separado por un espacio despues de su respectiva password OJITO!! hay que especificar la password tambien en el fichero si se pone el usuario en el fichero"
        echo "Ejemplo del fichero con password incluida: skynet-server WeWillRise root"
        echo "Ejemplo de uso del comando: envio_ficheros.sh -f ultimate_trojan -u jconnor -p /home/resistance -M /home/user/skynet-servers -P WeWillRise"
}


if [ $# -eq 0 ]; then 
        echo "No se han introducido parametros"
        print_uso
        exit 3
fi






while [ $# -gt 0 ]; do
        case $1 in
        "-h") print_uso
			  exit 0
        shift
;;
      	"-f") FICHERO=$2	
        shift
;;
      	"-M") LISTA=$2
        shift
;;
      	"-P") CONTRASENA=$2
        shift
;;
      	"-u") USUARIO=$2
        shift
;;
      	"-p") RUTA=$2
        shift
;;
        *)
        shift
esac
done


if [ -z $FICHERO ] || [ -z $LISTA ]; then
	    echo "No se han introducido parametros suficientes parametros"

        if [ -z $FICHERO ]; then
       	   echo "No se ha introducido un fichero a enviar"
        fi

        if [ -z $LISTA ]; then
        	echo "No se ha introducido un fichero con la lista de maquinas a enviar"
        fi

        print_uso
        exit 3
fi


 if [ -z "$USUARIO" ]; then
       USUARIO=$(logname)
 fi

if [ -n "$CONTRASENA" ]; then
	   MULTIPASE="sshpass -p"$CONTRASENA
fi


i=1
ERR=0
BUENOS=0
CUENTAFALLOS=0
CUENTABUENOS=0


grep -v ^# $LISTA |while read MAQUINA PASSFICHERO USR
do

if [ -n "$PASSFICHERO" ]; then
	MULTIPASE="sshpass -p"$PASSFICHERO
    if [ -n "$USR" ]; then
    USUARIO=$USR
    fi
fi
#habria que filtrar que el fichero de maquinas no tenga ningun espacio al final del nombre de la maquina si no tiene password 
    echo "--TARGET--" $MAQUINA
	$MULTIPASE $SCP $FICHERO $USUARIO@$MAQUINA:$RUTA > /dev/null
	   	
	   	if [ $? -ne 0 ]; then
	    ERR=$(($ERR+1))
	    CUENTAFALLOS=$(($CUENTAFALLOS+1))
	    FALLOS[$ERR]=`echo $MULTIPASE " scp"  $FICHERO $USUARIO"@"$MAQUINA":"$RUTA`
	else
		BUENOS=$(($BUENOS+1))
		CUENTABUENOS=$(($CUENTABUENOS+1))
		CORRECTOS[$BUENOS]=`echo $MULTIPASE " scp"  $FICHERO $USUARIO"@"$MAQUINA":"$RUTA`
	fi
	if [ -n "$CONTRASENA" ]; then
	   MULTIPASE="sshpass -p"$CONTRASENA
    fi
 	i=$(($i+1))	
done

if [ "$ERR" -ge 1 ]; then
	echo "Han fallado las siguientes transferencias: "
	CONTADORFALLOS=0
	ERR=0
	until [ $CONTADORFALLOS -gt $CUENTAFALLOS ]; do
		ERR=$(($ERR+1)) 	
		echo ${FALLOS[$ERR]}
		CONTADORFALLOS=$(($CONTADORFALLOS+1))
	done
fi

if [ "$BUENOS" -ge 1 ]; then
echo "Se supone que las siguientes transferencias se han realizado con exito"
	CONTADORBUENOS=0
	BUENOS=0
	until [ $CONTADORBUENOS -gt $CUENTABUENOS ]; do
		BUENOS=$(($BUENOS+1)) 	
		echo ${CORRECTOS[$BUENOS]}
		CONTADORBUENOS=$(($CONTADORBUENOS+1))
	done	
fi

exit 0
