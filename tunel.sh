#!/bin/ksh

### Script para creación y gestión de tuneles SSH
### 0.7 3/5/16
### Daniel Molina

LISTA=0
VECES=`ps aux | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$15'} | wc -l`
i=1
es_numero='^[0-9]+$'
print_uso()
{
        echo "Uso: "
        echo "Si no se especifica un puerto local creara el tunel en el puerto LOCAL 8000"
        echo "Si no se especifica un puerto remoto creara el túnel en el puerto REMOTO 80"
        echo "SI que es necesario indicar la maquina de salto del cliente al que saltar"
        echo "-l puerto local"
        echo "-r puerto remoto"
        echo "-h host al que hacer el salto"
        echo "-s host intermediario del salto"
        echo "-u usuario de la maquina intermediaria del salto, sin parametros dmolina"
        echo "-o -list para mostrar una lista de los tuneles abiertos con este script"
        echo "Usa el parametro -list para mostrar los tuneles abiertos, con -o para solo usar la funcion de lista"
        echo "Ejemplo de uso ./tunel.sh -l 8000 -r 80 babanew"
}

fusilar()
{
#    echo "tunel:" 
#    ps aux | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$15'}
#    echo "numero de proceso:"
#    ps aux | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$2'}
VECES=`ps aux | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$15'} | wc -l`


# muestra el pid del tunel
i=1
until [ $i -gt $VECES ]; do
    PROCESOS[$i]=`ps aux | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$2'} | sed -n $(($i))p`
   i=$(($i+1))
done

i=1
until [ $i -gt $VECES ]; do
    NOMBRES[$i]=`ps aux | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk '{print$15 ":"  $16 }' | sed -n $(($i))p`
   i=$(($i+1))
done

echo "Tuneles abiertos: ${#PROCESOS[*]}"

echo "Introduce el número del proceso que quieres borrar (1 a" $VECES"):"
for index in ${!NOMBRES[*]}
do
    printf "%4d: %s\n" $index ${NOMBRES[$index]}
# muestra el pid del tunel
#    printf "%4d: %s\n" $index ${PROCESOS[$index]}
done
}

### Lectura de parametros
if
[ $# -eq 0 ]
        then echo "No se han introducido parametros"
        
        print_uso
        exit 3
else
while [ $# -gt 0 ];
do
        case $1 in
        "-r") REMOTO=$2
        shift
;;
        "-l") LOCAL=$2
        shift
;;
        "-h") SALTO=$2
        shift
;;
        "-u") USUARIO=$2
        shift
;;
        "-s") INTERMEDIARIO=$2
        shift
;;
        "-list") LISTA=1
        shift
;;
        "-o") OMITIR=1
        shift
;;
        *)
        shift
esac
done
fi
### Comprobacion de parametros
if [ -z $OMITIR ]
then

if [ -z $REMOTO ] ; then 
        REMOTO=80
        echo "No se ha dado un puerto REMOTO por parametro, usando el puerto $REMOTO..."
        
fi

if [ -z $LOCAL ] ; then 
        echo "No se ha dado un puerto LOCAL por parametro, usando el puerto 8000 en adelante"
        LOCAL=8000
        
fi

if [ -z $USUARIO ] ; then 
        echo "No se ha dado un usuario por parametro, usando $USUARIO"
        USUARIO=dmolinao
        
fi

if [ -z $INTERMEDIARIO ] ;then 
        echo "No se ha dado una maquina intermediaria por parametro, usando $INTERMEDIARIO"
        INTERMEDIARIO=192.168.150.136
fi

if [ -z $SALTO ]
                then echo "No se ha dado una máquina de salto, saliendo..."
                exit 3
fi

fi





#temporal

if [ -z $OMITIR ]
then

until [ $i -gt $VECES ]; do
    PUERTOS[$i]=`ps aux | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$15'} |cut -d ":" -f 1 | sort | sed -n $(($i))p`
   i=$(($i+1))
done
i=1

until [ $i -gt $VECES ]; do
    if [ ${PUERTOS[$i]} -eq $LOCAL ]
        then
        let LOCAL=$LOCAL+1 
        i=$(($i+1))
        else
        i=$(($i+1))
fi
   done
#temporal ^
ssh -f -N -L $LOCAL:$SALTO:$REMOTO $USUARIO@$INTERMEDIARIO
 while [ $? -ne 0 ];
    do 
    echo "Contraseña erronea, vuelva a introducirla:"
    ssh -f -N -L $LOCAL:$SALTO:$REMOTO $USUARIO@$INTERMEDIARIO
    done
echo "Tunel: " $LOCAL":"$SALTO":"$REMOTO  a través de $USUARIO@$INTERMEDIARIO
fi


## Listar y preguntar si quieres matar procesos

ALGUNO=`ps -ef | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$2'}| sed -n 1p`
ABIERTOS=`ps -ef | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$2'}`
if [ $LISTA -eq 1 ]
        then
            if [ -z $ABIERTOS ]
                then
                echo "No hay tuneles abiertos"
                exit 0
                else
                fusilar
                echo "Quieres matar un proceso? (s/n)"
                read "MATAR2"
                until [ "$MATAR2" = "n" -o "$MATAR2" = "s" ];
                do
                  echo "Parametro invalido, vuelve a introducirlo"
                  echo "Quieres matar un proceso? (s/n)..." 
                  read MATAR2
                done
                if [ $MATAR2 = "n" ]     
                then
                echo "Saliendo" 
                exit 0
                else 
                    while [ -n $ALGUNO ];
                    do
                        if [ "$MATAR2" = "s" ]
                        then 
                            echo "Cual quieres matar?"
                            echo "OJO!! Se cerrará el túnel, asegurate de no tener tareas a través de él a mitad!!!!"

                            fusilar
                            echo 
                            read MATANZA
###Comprobacion de que MATANZA sea un valor válido
                            while [ -z "$MATANZA" ];
                            do 
                            echo "Tienes que introducir un numero de tunel a cerrar"
                            read MATANZA
                            done
                            unset ENTERO
                            let ENTERO=MATANZA+1 > /dev/null
                            until [ $? -eq 0 ] ; do
                            echo "Tienes que introducir un numero" 
                            read MATANZA
                            unset ENTERO
                            let ENTERO=MATANZA+1 > /dev/null
                            done
                            while [ $MATANZA -gt $VECES ]; do
                            echo "Tienes que introducir un numero de tunel valido, de 1 a" $VECES    
                            read MATANZA
                            unset ENTERO
                            let ENTERO=MATANZA+1 > /dev/null
                            if [ $? -eq 0 ] ; then
                            echo "Tienes que introducir un numero" 
                            read MATANZA
                            unset ENTERO
                            let ENTERO=MATANZA+1 > /dev/null
                            fi
                            done
                            kill ${PROCESOS[$MATANZA]}
                            echo "proceso " ${PROCESOS[$MATANZA]} "->" ${NOMBRES[$MATANZA]} " matado"
                            unset PROCESOS
                            unset NOMBRES
                        else 
                            exit 0
                        fi
                        ABIERTOS=`ps -ef | grep -v grep| grep -v "/usr/sbin/sshd" | grep "ssh -f -N -L" |awk {'print$12'}`
                            if [ -z $ABIERTOS ]
                            then 
                            echo "Todos los tuneles cerrados"
                            exit 0
                            else 
                            echo "quieres cerrar otro tunel? (s/pulsa cualquier otra cosa para salir)"
                            read MATAR2
                            fi
                    done
                fi

fi
fi
echo "Saliendo..."
exit 0