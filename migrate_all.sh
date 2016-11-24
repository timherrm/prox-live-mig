#!/bin/bash
#################################################################################
rm -f migration.log;								#
vm_array=($(qm list | awk '{print $1}' | grep -Eo '[0-9]{1,3}'));		#
i=0;										#
while [ $i -lt "${#vm_array[@]}" ];						#
do										#
err="0";									#
vm=${vm_array[$i]};								#
#.............................................................................###

####### Informationen sammeln ###################################################################################################
																#
####### Anzahl Nodes auslesen und als Array speichern ###########################################				#
node_array=($(pvecm nodes | tail -n $(expr $(pvecm nodes | wc -l) - 4) | awk '{print $3}'));	#				#
#################################################################################################				#
																#
for host in "${node_array[@]}"													#
do																#
####### CPU #############################################################							#
	ssh=$(ssh $host -C "cut -d ' ' -f3 /proc/loadavg" 2>/dev/zero)	#							#
	printf $host >> get.txt;					#							#
        printf ":  " >> get.txt;					#							#
	if [[ $ssh ]]; then						#							#
		printf $ssh >> get.txt;					#							#
		printf "\n" >> get.txt;					#							#
	else								#							#
		printf "9.99 - offline" >> get.txt;			#							#
		printf "\n" >> get.txt;					#							#
	fi								#							#
#########################################################################							#
																#
####### RAM #############################################################################################################	#
        ssh=$(ssh $host -C bc -l <<< "$(free -m | grep buffers/cache | awk '{print $3+$4}') / 1024" 2>/dev/zero)	#	#
        printf $host >> get2.txt;											#	#
        printf ":  " >> get2.txt;											#	#
        if [[ $ssh ]]; then												#	#
                printf $ssh >> get2.txt;										#	#
                printf "\n" >> get2.txt;										#	#
        else														#	#
                printf "0.00 - offline" >> get2.txt;									#	#
                printf "\n" >> get2.txt;										#	#
        fi														#	#
#########################################################################################################################	#
done																#
#################################################################################################################################


####### Informationen auswerten #################################################################################
														#
####### Sortieren ###############################								#
sort -t':' -nk2 get.txt > sort.txt;		#								#
sort -t':' -nk2 -r get2.txt > sort2.txt;	#								#
#################################################								#
														#
####### Bash-Parameter auslesen #########									#
getopts "q::" opt;			#									#
	case $opt in			#									#
		q)			#									#
			qnode=$OPTARG;	#									#
			;;		#									#
		\?)			#									#
			qnode="false";	#									#
			;;		#									#
	esac				#									#
#########################################									#
														#
####### schließe eigenen Host + Quorum-Node aus #########################					#
cat "sort.txt" | grep -v -e $(hostname) -e "$qnode" > cpulog.txt;	#					#
cat "sort2.txt" | grep -v -e $(hostname) -e "$qnode" > ramlog.txt;	#					#
#########################################################################					#
														#
####### Ausgabe #########################################################################################	#
echo;													#	#
printf "Niedrigste CPU-Auslastung der letzten 10 Minuten: "; head -n1 cpulog.txt | cut -d ":" -f1;	#	#
printf "Niedrigste RAM-Auslastung: "; head -n1 ramlog.txt | cut -d ":" -f1;				#	#
echo;													#	#
													#	#
echo;													#	#
echo "################ CPU ###################";							#	#
cat cpulog.txt												#	#
echo;													#	#
echo "################ RAM ###################";							#	#
cat ramlog.txt												#	#
echo;													#	#
#########################################################################################################	#
														#
####### Host zur Migration festlegen ####################							#
migr_host=$(head -n1 cpulog.txt | cut -d ":" -f1;)	#							#
#########################################################							#
														#
rm -f sort.txt get.txt sort2.txt get2.txt cpulog.txt ramlog.txt;						#
#################################################################################################################

#.............................................................................###
mig_output=$(qm migrate "$vm" "$migr_host" --online );				#
										#
if [[ $mig_output == *"ERROR"* ]];						#
then										#
	echo -ne '\E[31;40m';							#
	echo "Fehler auf VM:" $vm;						#
										#
	if [[ $mig_output == *"local cdrom image"* ]];				#
	then									#
		echo "Lokales CD/DVD-Image gefunden:";				#
		qm config "$vm" | grep "local:iso";				#
		lport=$(qm config "$vm" | grep "local:iso" | cut -d ":" -f1);	#
		rmdisk=$(qm unlink "$vm" --idlist "$lport");			#
		printf "Entferne CD/DVD-Image $lport";				#
		if [[ $rmdisk == *"update VM"* ]];				#
		then								#
			echo -ne '\E[32;40m';					#
			echo "...ok";						#
		else								#
			echo "Fehler beim Auswerfen des Images";		#
		fi								#
	fi									#
										#
	echo -ne '\E[0m';							#
	vm_array+=("$vm");							#
	err="1";								#
else										#
	if [[ $mig_output == *"found local disk"* ]];				#
	then									#
		echo -e '\E[33;40m';						#
		echo "Lokale Festplatte von VM " $vm " migriert.";		#
		echo -e '\E[0m';						#
	fi									#
	printf $migr_host >> migration.log;					#
	printf "  :  " >> migration.log;					#
	printf $vm >> migration.log;						#
	printf "  :  " >> migration.log						#
	printf "$(date)" >> migration.log					#
	printf "\n" >> migration.log;						#
	echo -e '\E[32;40m';							#
	printf "Verschiebe VM ";						#
	printf $vm;								#
	printf " nach ";							#
	printf $migr_host;							#
	printf "\n";								#
	echo -e '\E[0m';							#
fi										#
										#
if [ $i -lt $(expr "${#vm_array[@]}" - 1 ) ] && [ $err == "0" ];		#
then										#
	echo -e '\E[36;40m';							#
	echo -ne "Warte 10 Minuten";						#
	sleep 600;								#
	echo -e '\E[0m';							#
elif [ $err == "1" ];								#
then										#
	echo -e '\E[36;40m';							#
	echo -ne "VM nicht migriert, Wartezeit überspringen";			#
	echo -e '\E[0m';							#
fi										#
										#
let i+=1;									#
done										#
#################################################################################
