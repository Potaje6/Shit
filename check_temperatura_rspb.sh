#!/bin/bash
##0.1
##Daniel Molina
##Chequeo para medir la temperatura de la raspberry-pi de las pantallas
#/usr/bin/vcgencmd measure_temp |sed 's/temp=//g'|sed 's/C//g'| sed 's/.$//g'



print_uso()
{
echo "Uso del script:"
echo "-w para establecer una temperatura de peligro, 53 grados por defecto"
echo "-c para establecer una temperatura critica, 57 grados por defecto"
echo "-h para mostrar esta ayuda"
echo "-d para chequear la temperatura a la inversa, si la temperatura es menor a los umbrales saltara la alarma"
}


WARNING=53
CRITICAL=57
DEBUG=\<

while [ $# -gt 0 ];
do
        case $1 in
        "-w") WARNING=$2
        shift
;;
        "-c") CRITICAL=$2
        shift
;;
        "-h") print_uso
        shift
;;
        "-d") DEBUG=\>
        shift
;;
        *)
        shift
esac
done


TEMPERATURA=`/usr/bin/vcgencmd measure_temp |sed 's/temp=//g'|sed 's/C//g'| sed 's/.$//g'`

CRITICA=`echo "$TEMPERATURA $DEBUG $CRITICAL" |bc`

if [ $CRITICA -eq 0 ]; then
	echo `date +"%m-%d-%Y--%T"` "-----" "CRITICAL - temperatura de la raspberry-pi a " $TEMPERATURA "'C" >> /home/nologin/temperatura.log
	exit 2
	poweroff
fi

WARNING=`echo "$TEMPERATURA $DEBUG $WARNING" |bc`

if [ $WARNING -eq 0 ]; then
	echo `date +"%m-%d-%Y--%T"` "-----"  "WARNING - temperatura de la raspberry-pi a " $TEMPERATURA "'C" >> /home/nologin/temperatura.log
	exit 1
fi

#echo `date +"%m-%d-%Y--%T"` "-----"  "OK - temperatura de la raspberry-pi a " $TEMPERATURA "'C" >> /home/nologin/temperatura.log
exit 0
