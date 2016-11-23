#!/bin/bash
if [ ! -e migration.log ]
then
	exit 0
fi

####### Migrations-Log lesen ####################################################
migstats=($(cat migration.log | awk -F '  :  ' '{print $1; print $2}'));	#
#################################################################################

####### VM's zurückholen ########################################################
i=0;										#
while [ $i -lt "${#migstats[@]}" ];						#
do										#
	host=${migstats[$i]};							#
	vm=${migstats[ $expr( $i + 1 ) ]};					#
										#
	back_out=$(ssh $host -C "qm migrate $vm $(hostname) --online");		#
										#
	if [[ $back_out == *"found local disk"* ]];				#
	then									#
		echo -e '\E[33;40m';						#
		printf "Lokale Festplatte von VM $vm migriert!";		#
		echo -e '\E[0m';						#
	fi									#
										#
	if [[ $back_out == *"migration finished successfully"* ]];		#
	then									#
		echo -e '\E[32;40m';						#
		printf "VM $vm erfolgreich zurück migriert!";			#
		echo -e '\E[0m';						#
	fi									#
										#
	if [[ $back_out == *"Executing HA migrate"* ]];				#
	then									#
		echo -e '\E[32;40m';						#
		printf "HA Migration für VM $vm angestoßen!";			#
		echo -e '\E[0m';						#
	fi									#
										#
	let i+=2;								#
done										#
#################################################################################
rm migration.log
