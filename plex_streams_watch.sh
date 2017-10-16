#!/bin/bash

# https://support.plex.tv/hc/en-us/articles/204059436-Finding-an-authentication-token-X-Plex-Token
XPlexToken="YourXPlexToken"

# https://telegram.me/trafficRobot
trafficroboturl="YourTrafficRobotURL"

_check_plex_streams () {
echo "---------------------------------------"
echo "Checking current Plex streams..."
nbplexstreams=$(curl --silent localhost:32400/status/sessions?X-Plex-Token=$XPlexToken | grep '<MediaContainer' | cut -c23)
echo "There is/are currently $nbplexstreams Plex streams !"
echo "---------------------------------------"
}

while true
do
	clear
	_check_plex_streams
	if [ "$nbplexstreams" == "0" ]; then
		if [ "$mining" == "" ]; then
			echo "Starting workers..."
			mining="yes"
			curl --silent -X POST -d "Start mining !" $trafficroboturl > /dev/null
		else
			echo "- CURRENTLY MINING -"
		fi
	else
		if [ "$mining" = "yes" ]; then
			echo "Stopping workers..."
			mining=""
			curl --silent -X POST -d "Stop mining !" $trafficroboturl > /dev/null
		else
			echo "- PLEX STREAMS IN PROGRESS -"
		fi
	fi
	for i in {3..1};do echo -n "$i " && sleep 1; done
done
