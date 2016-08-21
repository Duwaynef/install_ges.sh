#!/bin/bash
# Bash script created by DEATH
# August 16th 2016
# pre installing
# apt-get install vsftpd nano
# nano /etc/vsftpd.conf
# remove # from write_enable=YES
# find pam_service_name=vsftpd and change vsftpd to ftp
# service vsftpd restart
# if [ -x $(command -v apt-get >/dev/null) ]

#Install file locations

steamdl='https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz'
serverfilesdl='http://files-us.gamestand.net/GoldenEye_Source_v5.0_full_server.7z'
serversodl=''
serversmdl='https://www.sourcemod.net/smdrop/1.8/sourcemod-1.8.0-git5928-linux.tar.gz'
servermmdl='http://www.gsptalk.com/mirror/sourcemod/mmsource-1.10.6-linux.tar.gz'
prerequisites='gcc-4.9 g++-4.9 p7zip-full sudo wget nano lib32gcc1 lib32stdc++6 lib32z1 gdb'

if [ "$1" == "-h" ] || [ "$1" == "--h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ];then
	echo ''
	echo 'For automated install, '
	echo 'ex. ./install_ges.sh -a steam STEAM:0:0:12345'
	echo 'or  ./install_ges.sh -a steam STEAM:0:0:12345 "-game ./gesource/ -console +maxplayers 16 +map ge_archives +exec server.cfg"'
	echo ''
	echo 'Second option is be specific for what to install.'
	echo 'in this order, '
fi

if [ "$1" == "-a" ] || [ "$1" == "-A" ] && [ "$2" != "" ] && [ "$3" != "" ] && [ "$4" == "" ];then

	installsm=Y
	doinstallsm=Y
	installservice=Y
	doinstallservice=Y
	useraccount=$2
	steamid=$3
	automated=Y
	usrstop=0

fi
if [ "$1" == "-a" ] || [ "$1" == "-A" ] && [ "$2" != "" ] && [ "$3" != "" ] && [ "$4" != "" ];then

	installsm=Y
	doinstallsm=Y
	installservice=Y
	doinstallservice=Y
	useraccount=$2
	steamid=$3
	serviceprams=$4
	automated=Y
	usrstop=0

fi

clear

#Some housekeeping variables

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`
UL=$(tput cuu1)
EL=$(tput el)
curdir=$(pwd)

#welcome screen

echo "${green}"
echo "	|-------------------------------------------------------------------|"
echo "	|	Welcome to the GoldenEye:Source server installer by ${red}DEATH${green}   |"
echo "	|	This Script will install all the required prerequisites     |"
echo "	|	including steamcmd, server files, library files, ect.       |"
echo "	|	                                                            |"
echo "	|	This script has been tested on ubuntu server                |"
echo "	|	it may not work on different distributions                  |"
echo "	|-------------------------------------------------------------------|"
echo "${reset}"

if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi

#install the required prerequisites for server, start task in the background

{
apt-get upgrade -y -qq > /dev/null 2>&1

apt-get update -y -qq > /dev/null 2>&1

apt-get install -y software-properties-common -qq > /dev/null 2>&1

add-apt-repository -y ppa:ubuntu-toolchain-r/test > /dev/null 2>&1

apt-get update -y -qq > /dev/null 2>&1

apt-get install -y $prerequisites -qq > /dev/null 2>&1
} &
pid1=$!

if [ "$automated" != "Y" ];then

	echo "	${green}Please specify a user account to create for the server, do not use root"
	echo "	The account specified will be created and the home directory used for the server"
	echo "	It is highly suggested to use a new account for this."
	echo "	${reset}"

	#require non root user account with warning for using an already existing user account
	read -p '	Username: ' useraccount	
	op=":"
	while :
		do					
			if [ "$useraccount" == "root" ] || [ "$useraccount" == "" ]; then
				echo '	You cannot use root or blank, please specify an account to create: '
			elif [ "$(sudo grep -c $useraccount$op /etc/passwd)" == "1" ]; then
				echo	""
				echo 	"	${green}${useraccount}${red} already exists, are you sure you want to use this account"
				echo 	"	this script will write the server files to ${green}/home/${useraccount}/"
				echo	"${reset}"
				read -p '	Use this account?[y/n]: ' usetheaccount	
				if [ "$usetheaccount" == "n" ] || [ "$usetheaccount" == "N" ] || [ "$usetheaccount" == "" ]; then
					read -p '	specify a new account: ' useraccount
					echo -n "	Use account?[${green}${useraccount}${reset}] "
					read -p '[y/n]: ' useusr
				fi 
				if [ "$usetheaccount" == "y" ] || [ "$usetheaccount" == "Y" ]; then
					useusr="y"
				fi
			elif [ "$useusr" != "y" ];then
				echo
				echo -n "	Use account?[${green}${useraccount}${reset}] "
				read -p '	[y/n]: ' useusr						
			fi
			if [ "$useusr" == "y" ] || [ "$useusr" == "Y" ];then
				break
			fi
	done
fi
echo

#add the user from the command above, with no output

adduser --disabled-password --gecos "" $useraccount > /dev/null 2>&1

#ask user if the server should be installed as a service
if [ "$automated" != "Y" ];then
	read -p '	Install server as a service? [y/n]: ' installservice
	while :
	do		
		if [ "$installservice" == "y" ] ||  [ "$installservice" == "Y" ] || [ "$installservice" == "N" ] ||  [ "$installservice" == "n" ];then
			break
		fi
		read -p '	Install server as a service? [y/n]: ' installservice
	done
fi
#if the user says yes to install as a service, setup the server file for creation
servername="GoldenEye: Source v5.0 Server"
servermaxplayers=16
serverpassword=""
serverregion=0
serverrcon=""
if [ "$automated" != "Y" ];then
	echo "	Lets setup some server variables"
	echo ""
	read -p "	Server Name?[${servername}]: " servername
	read -p "	Max Players?[${servermaxplayers}](please stay at 16 or under): " servermaxplayers
	read -p "	If you want your server to be private, fill in a password[${serverpassword}]: " serverpassword
	read -p "	Enter a rcon password[${serverrcon}]: " serverrcon
	echo "	0=US East coast, 1=US West coast, 2= South America, 3=Europe, 4=Asia, 5=Australia,"
	read -p "	6=Middle East, 7=Africa and 255=world sv_region 0 [${serverregion}]: " serverregion
fi
if [ "$installservice" == "y" ] || [ "$installservice" == "Y" ] || [ "$installservice" == "yes" ] || [ "$installservice" == "Yes" ] || [ "$installservice" == "YES" ]; then
		
		doinstallservice="Y"
		serviceuser="SRCDS_USER='$useraccount'"
		servicedir="DIR='/home/$useraccount/ges_server/'"
		serviceprams='-game ./gesource/ -console +maxplayers '$servermaxplayers' -norestart +map ge_archives +exec server.cfg'
		
		if [ "$automated" != "Y" ];then
			echo "${green}"
			echo "	server launch parameters?"
			echo "	[def]:${yellow} ${serviceprams}${green}"
			echo '	Enter custom launch prameters or press enter for default: '
			echo "${reset}"
			read -p '	[PRAMS]: ' praminput
			echo ""
		fi
		if [ "$praminput" != "" ];then
			serviceprams=$praminput
		fi
		servicelaunch="PARAMS='$serviceprams'"
else
	doinstallservice="N"
fi

#ask the user if they want source mod installed(admin mod).

if [ "$automated" != "Y" ];then
read -p '	Install Source Mod?(Admin mod, mute,kick,ban,ect.) [y/n]: ' installsm

	while :
	do
		if [ "$installsm" == "y" ] ||  [ "$installsm" == "Y" ] || [ "$installsm" == "N" ] ||  [ "$installsm" == "n" ];then
			break
		fi
		read -p '	Install Source Mod? [y/n]: ' installsm
	done
fi
echo

#if the user says yes to installing source mod, set to doinsall as a simple variable to avoid checking for all yes inputs

if [ "$installsm" == "y" ] || [ "$installsm" == "Y" ] || [ "$installsm" == "yes" ] || [ "$installsm" == "Yes" ] || [ "$installsm" == "YES" ]; then
	doinstallsm="Y"
else
	doinstallsm="N"
fi

#if the user said yes to installing source mod, ask for their steam id to add them as the first admin

if [ "$doinstallsm" == "Y" ] && [ "$automated" != "Y" ]; then
	echo "${green}		To get your current steam ID, open a source based game"		
	echo "		join a server and type status in console"
	echo "		your steamid will look like ${yellow}"STEAM_0:0:12345"${green}"
	echo "		leave blank if you don't want the script to add your id as admin${reset}"
	echo "${reset}"
	read -p "	What is your steam id? [ex. STEAM_0:0:123456]: " steam_id
	echo ""
fi

#here we wait to make sure that apt-get commands are finished as they were running in the background during the questions

echo "	${green}Waiting for prerequisites to finish installing..${reset}"
cp install_ges.sh /home/$useraccount/
cd /home/$useraccount/

wait $pid1

#start folder creation in the background

mkdir -p /home/$useraccount/ges_downloads
mkdir -p /home/$useraccount/steamcmd
mkdir -p /home/$useraccount/ges_server
mkdir -p /home/$useraccount/ges_server/gesource
mkdir -p /home/$useraccount/ges_server/gesource/bin
chown -R $useraccount:$useraccount /home/$useraccount
echo &
pid9=$!

cd /home/$useraccount/ges_downloads

#start the download for the required files, each task spawned in the background so they download the same time

su $useraccount -c 'wget -c -q "'${serversodl}'" -O server_i486.tar.gz' &
pid2=$!

su $useraccount -c 'wget -c -q '${steamdl}' --no-check-certificate' &
pid3=$!

su $useraccount -c 'wget -c -q '${serverfilesdl}' -O gesource.7z' &
pid4=$!

#if user said yes to install source mod, download required files and install them

{
if [ "${doinstallsm}" == "Y" ]; then
	su $useraccount -c 'wget -nc -q '${servermmdl}' -O sourcemm.tar.gz'
	su $useraccount -c 'wget -nc -q '${serversmdl}' -O sourcesm.tar.gz'
	su $useraccount -c 'tar -xf sourcemm.tar.gz -C /home/'${useraccount}'/ges_server/gesource/ > /dev/null'
	su $useraccount -c 'tar -xf sourcesm.tar.gz -C /home/'${useraccount}'/ges_server/gesource/ > /dev/null'
	echo " addons/sourcemod/bin/sourcemod_mm" >> /home/$useraccount/ges_server/gesource/addons/metamod/metaplugins.ini
	if [ "${steam_id}" != "" ]; then
		 echo "'${steam_id}' 'z'" >> /home/$useraccount/ges_server/gesource/addons/sourcemod/configs/admins_simple.ini
 	fi
fi
} &
pid5=$!

#start the extraction for the downloads, all wait on their downloads to finish before extracting

{
while [ -e /proc/${pid3} ]; do sleep 0.1; done
su $useraccount -c 'tar -xf steamcmd_linux.tar.gz -C /home/'${useraccount}'/steamcmd > /dev/null'
} &
pid11=$!

{
while [ -e /proc/${pid4} ]; do sleep 0.1; done
su $useraccount -c '7z x -y -o/home/'${useraccount}'/ges_server/gesource gesource.7z > /dev/null'
echo "" >> /home/${useraccount}/ges_server/gesource/cfg/server.cfg
if [ "$servername" != "GoldenEye: Source v5.0 Server" ];then echo 'hostname="'${servername}'"' >> /home/${useraccount}/ges_server/gesource/cfg/server.cfg;fi
if [ "$serverrcon" != "" ];then echo 'rcon_password="'${serverrcon}'"' >> /home/${useraccount}/ges_server/gesource/cfg/server.cfg;fi
if [ "$serverpassword" != "" ];then echo 'sv_password="'${serverpassword}'"' >> /home/${useraccount}/ges_server/gesource/cfg/server.cfg;fi
if [ "$serverregion" != "0" ];then echo 'sv_region="'${serverregion}'"' >> /home/${useraccount}/ges_server/gesource/cfg/server.cfg;fi
} &
pid6=$!

{
while [ -e /proc/${pid2} ]; do sleep 0.1; done
su $useraccount -c 'tar -xf server_i486.tar.gz -C /home/'${useraccount}'/ges_server/gesource/bin > /dev/null'
} &
pid7=$!

cd /home/$useraccount/steamcmd

{
while [ -e /proc/${pid11} ]; do sleep 0.1; done
chown -R $useraccount:$useraccount /home/$useraccount/*
chown -R $useraccount:$useraccount /home/$useraccount/steamcmd
su $useraccount -c '/home/'${useraccount}'/steamcmd/steamcmd.sh +logon anonymous +force_install_dir /home/'${useraccount}'/ges_server +app_update 310 +quit > /dev/null'
} &
pid8=$!

cd /home/$useraccount/
#generate update_ges.sh and run_ges.sh files for the user

echo "" > /home/$useraccount/run_ges.sh
echo 'MALLOC_CHECK_=0 ./srcds_run -game ./gesource -console +maxplayers '$servermaxplayers' +map ge_archives +exec server.cfg' | cat - /home/$useraccount/run_ges.sh > temp && mv temp /home/$useraccount/run_ges.sh
echo 'cd ges_server' | cat - /home/$useraccount/run_ges.sh > temp && mv temp /home/$useraccount/run_ges.sh

echo "" > /home/$useraccount/update_ges.sh
echo './steamcmd.sh +logon anonymous +force_install_dir /home/'${useraccount}'/ges_server +app_update 310 validate +quit' | cat - /home/$useraccount/update_ges.sh > temp && mv temp /home/$useraccount/update_ges.sh
echo 'cd steamcmd' | cat - /home/$useraccount/update_ges.sh > temp && mv temp /home/$useraccount/update_ges.sh

#installing the server service

if [ "$doinstallservice" == "Y" ]; then
{
	cat > /etc/init.d/ges_server <<- "EOF5"

		PATH=/bin:/usr/bin:/sbin:/usr/sbin
		DESC="GoldenEye Source Dedicated Server"
		NAME=ges_server
		PIDFILE=/var/run/$NAME.pid
		SCRIPTNAME=/etc/init.d/$NAME

		export MALLOC_CHECK_=0

		[ -x "$DAEMON" ] || exit 0

		DAEMON_ARGS="-steam_dir $DIR -steamcmd_script $DIR/steamcmd.sh -pidfile $PIDFILE $ARGS $CVARS"

		. /lib/init/vars.sh
		. /lib/lsb/init-functions

		do_start() {
			# Help srcds out by making the PID file and
			# chowning it seeing as it doesnt like doing that itself
			export MALLOC_CHECK_=0
			touch $PIDFILE
			chown $USER $PIDFILE
			# Check to see its running first
			start-stop-daemon --start --quiet --pidfile $PIDFILE --chuid $USER:$GROUP --chdir $CHDIR --exec $DAEMON --test > /dev/null || return 1
			# Start the SRCDS running
			start-stop-daemon --start --pidfile $PIDFILE --background --chuid $USER --chdir $CHDIR --exec $DAEMON -- $DAEMON_ARGS || return 2
		}
		do_stop() {
			start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --user $USER
			RETVAL="$?"
			[ "$RETVAL" = 2 ] && return 2
			start-stop-daemon --stop --quiet --oknodo --retry=TERM/30/KILL/5 --exec $DAEMON
			[ "$?" = 2 ] && return 2
			# Delete the PID file
			rm -f $PIDFILE
			return "$RETVAL"
		}
		case "$1" in
			start)
				[ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
				do_start
				case "$?" in
					0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
					2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
				esac
				;;
			stop)
				[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
				do_stop
				case "$?" in
					0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
					2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
				esac
				;;
			status)
				status_of_proc -p $PIDFILE "$DAEMON" "$NAME" && exit 0 || exit $?
				;;
			restart)
				log_daemon_msg "Restarting $DESC" "$NAME"
				do_stop
				case "$?" in
					0|1)
						do_start
						case "$?" in
							0) log_end_msg 0 ;;
							1) log_end_msg 1 ;; # old process still running
							*) log_end_msg 1 ;; # Failed to start
						esac
						;;
					*)
						# Failed to stop
						log_end_msg 1
						;;
				esac
				;;
			*)
				echo "Usage: $SCRIPTNAME {start|stop|restart|status}" >&2
				exit 3
				;;
		esac
	exit 0

	EOF5
		echo 'ARGS="'${serviceprams}'"' | cat - /etc/init.d/ges_server > temp && mv temp /etc/init.d/ges_server
		echo 'CHDIR=/home/'${useraccount}'/ges_server' | cat - /etc/init.d/ges_server > temp && mv temp /etc/init.d/ges_server
		echo 'DIR=/home/'${useraccount}'/steamcmd' | cat - /etc/init.d/ges_server > temp && mv temp /etc/init.d/ges_server
		echo 'DAEMON=/home/'${useraccount}'/ges_server/srcds_run' | cat - /etc/init.d/ges_server > temp && mv temp /etc/init.d/ges_server
		echo 'USER="'${useraccount}'"' | cat - /etc/init.d/ges_server > temp && mv temp /etc/init.d/ges_server
		echo 'GROUP="'${useraccount}'"' | cat - /etc/init.d/ges_server > temp && mv temp /etc/init.d/ges_server
		echo "#!/bin/bash" | cat - /etc/init.d/ges_server > temp && mv temp /etc/init.d/ges_server
		chmod 755 /etc/init.d/ges_server
		systemctl daemon-reload

	} &
	pid10=$!
fi

#make the created files executable

chmod +x run_ges.sh
chmod +x update_ges.sh

#setup the three different status effects, waiting, running, and done.

pidwaiting="${red}WAITING${reset}"
pidrunning="${yellow}RUNNING${reset}"
piddone="${green}DONE${reset}"

#move into a while loop that wipes previous lines so it looks like the status is updating in spot

frn=1
while :
do
	if [ -e /proc/$pid9 ];then			
			dirstrpro=$pidrunning
		else
			dirstrpro=$piddone
	fi
	if [ -e /proc/$pid2 ];then
			svrsodl=$pidrunning
		else
			svrsodl=$piddone
	fi
		if [ -e /proc/$pid3 ];then
			cmddlpro=$pidrunning
		else
			cmddlpro=$piddone
	fi
		if [ -e /proc/$pid4 ];then
			gessvrdl=$pidrunning
		else
			gessvrdl=$piddone
	fi
		if [ -e /proc/$pid5 ] && [ "$doinstallsm" == "Y" ];then
			smipro=$pidrunning
		elif [ "$doinstallsm" == "Y" ];then
			smipro=$piddone
	fi
		if [ -e /proc/$pid10 ];then
			svsinpro=$pidrunning
		else
			svsinpro=$piddone
	fi
		if [ -e /proc/$pid3 ];then
			cmdextpro=$pidwaiting
		elif [ -e /proc/$pid11 ];then
			cmdextpro=$pidrunning
		else
			cmdextpro=$piddone
	fi
		if [ -e /proc/$pid4 ];then
			gessvrext=$pidwaiting
		elif [ -e /proc/$pid6 ];then
			gessvrext=$pidrunning
		else
			gessvrext=$piddone
	fi
		if [ -e /proc/$pid2 ];then
			svrsoext=$pidwaiting
		elif [ -e /proc/$pid7 ];then
			svrsoext=$pidrunning
		else
			svrsoext=$piddone
	fi
		if [ -e /proc/$pid11 ];then
			dedsvrext=$pidwaiting
		elif [ -e /proc/$pid8 ];then
			dedsvrext=$pidrunning
		else
			dedsvrext=$piddone
	fi
		if [ -e /proc/$pid1 ] || [ -e /proc/$pid2 ] || [ -e /proc/$pid3 ] || [ -e /proc/$pid4 ] || [ -e /proc/$pid5 ] || [ -e /proc/$pid6 ] || [ -e /proc/$pid7 ] || [ -e /proc/$pid8 ] || [ -e /proc/$pid9 ] || [ -e /proc/$pid10 ] || [ -e /proc/$pid11 ];then
			if [ "$frn" == "0" ];then 
			echo -e "$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL\c"
			fi
			frn=0
			echo "	${green}Create Directory Structure${reset} [ ${dirstrpro} ]"
			echo "	${green}Server_i486.so Download${reset} [ ${svrsodl} ]"
			echo "	${green}Steamcmd Download${reset} [ ${cmddlpro} ]"
			echo "	${green}GoldenEye:Source Server Files Download${reset} [ ${gessvrdl} ]"
			echo "	${green}Source Mod Install${reset} [ ${smipro} ]"
			echo "	${green}Service installation${reset} [ ${svsinpro} ]"
			echo "	${green}Extracting steamcmd${reset} [ ${cmdextpro} ]"
			echo "	${green}Extracting GoldenEye:Source Server files${reset} [ ${gessvrext} ]"
			echo "	${green}Extracting server_i486.so file${reset} [ ${svrsoext} ]"
			echo "	${green}Source 2007 Dedicated Server Install${reset} [ ${dedsvrext} ]"			
			sleep 1
		else
			echo -e "$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL$UL$EL\c"
			echo "	${green}Create Directory Structure${reset} [ ${dirstrpro} ]"
			echo "	${green}Server_i486.so Download${reset} [ ${svrsodl} ]"
			echo "	${green}Steamcmd Download${reset} [ ${cmddlpro} ]"
			echo "	${green}GoldenEye:Source Server Files Download${reset} [ ${gessvrdl} ]"
			echo "	${green}Source Mod Install${reset} [ ${smipro} ]"
			echo "	${green}Service installation${reset} [ ${svsinpro} ]"
			echo "	${green}Extracting steamcmd${reset} [ ${cmdextpro} ]"
			echo "	${green}Extracting GoldenEye:Source Server files${reset} [ ${gessvrext} ]"
			echo "	${green}Extracting server_i486.so file${reset} [ ${svrsoext} ]"
			echo "	${green}Source 2007 Dedicated Server Install${reset} [ ${dedsvrext} ]"	
			break
		fi
done

cd /home/$useraccount/
echo
echo "${green}	Finishing up...."

#run the update_ges.sh this has the validate command attached to ensure the server files downloaded properly

su $useraccount -c './update_ges.sh > /dev/null'
if [ "$doinstallservice" == "N" ];then
echo
echo  "		DONE! open ${yellow}run_ges.sh${green} with ${yellow}nano run_ges.sh"
echo  "		${green}and edit the launch options to your liking!"
echo  "		to update the server run ${yellow}./update_ges.sh${green}"
echo 
echo  "		now start your server with ${yellow}"screen ./run_ges.sh"${green} !!!"
echo  "		you can exit that screen and leave the server running with ${yellow}CTRL+A then d${green}"
else
echo
echo  "		DONE!"
echo  "		You choose to install GoldenEye Source Server as a service"
echo  "		you can operate the server with ${yellow}sudo service ges_server start${green}"
echo  "		Other ges_server commands are: start, stop, restart, status"
echo  ""
echo  "		To edit the server launch options type ${yellow}nano /etc/defult/ges_server${green}"
echo 
echo "${reset}"
fi

#switch to the specified user account

chown -R $useraccount:$useraccount /home/$useraccount/*

exit 0