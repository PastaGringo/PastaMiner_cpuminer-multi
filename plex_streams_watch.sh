#!/bin/bash

# https://support.plex.tv/hc/en-us/articles/204059436-Finding-an-authentication-token-X-Plex-Token
#XPlexToken="YourXPlexToken"

#need to add waring if variables below are not filled.

function _show_ascii () {
echo '          __          _               _                  '
echo '        / _ \__ _ ___| |_ __ _  /\/\ (_)_ __   ___ _ __  '
echo '       / /_)/ _` / __| __/ _  |/    \| |  _ \ / _ \  __| '
echo '      / ___/ (_| \__ \ || (_| / /\/\ \ | | | |  __/ |    '
echo '      \/    \__,_|___/\__\__,_\/    \/_|_| |_|\___|_|    '
echo
}



# https://telegram.me/trafficRobot
#trafficroboturl="YourTrafficRobotURL"

_check_plex_streams () {
datee=$(date)
echo "---------------------------------------"
echo "Checking current Plex streams..."
nbplexstreams=$(curl --silent localhost:32400/status/sessions?X-Plex-Token=$XPlexToken | grep '<MediaContainer' | cut -c23)
echo "$datee $nbplexstreams" >> time.log
echo "There is/are currently $nbplexstreams Plex stream(s) !"
echo "---------------------------------------"
}

while true
do
	clear
	_show_ascii
	_check_plex_streams
	if [ "$nbplexstreams" == "0" ]; then
		if [ "$mining" == "" ]; then
			echo "Starting workers..."
			mining="yes"
			curl --silent -X POST -d "Start mining !" $trafficroboturl > /dev/null
			./PastaMiner_cpuminer-multi.sh -startallworkers
			touch .flags/.plex_streams_watch_enabled
		else
			echo
			echo "- CURRENTLY MINING -"
		fi
	else
		if [ "$mining" = "yes" ]; then
			echo "Stopping workers..."
			mining=""
			curl --silent -X POST -d "Stop mining !" $trafficroboturl > /dev/null
			./PastaMiner_cpuminer-multi.sh -stopallworkers
			rm .flags/.plex_streams_watch_enabled
		else
			echo
			echo "- PLEX STREAMS IN PROGRESS -"
		fi
	fi
	echo
	for i in {3..1};do echo -n "$i " && sleep 1; done
done
