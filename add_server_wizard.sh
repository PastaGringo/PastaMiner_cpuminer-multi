#!/bin/bash
_easy_mode_wizard () {
clear
#_ask_coin
#_ask_wallet
#_ask_threads
#_ask_worker_name
_ask_server_pool
_ask_resume
#_start_worker $workername
}

_ask_resume () {
echo
echo $poolname
echo $poolserverurl
if [ "$registration" == "yes" ]; then
	echo $poolusername
	echo $poolworkername
	echo $poolworkerpassword
fi
_ask_question "Is it OK ? [y/n] " answer
}

_ask_question () {
echo
read -p "$1" $2
}

_server_pool_basics_question () {
_ask_question "What is the miner server pool name ? " poolname
_ask_question "What is the miner server pool URL ? " poolserverurl
}

_registration_server_pool () {
_server_pool_basics_question
_ask_question "Could you give me the username used from $poolname ? " poolusername
_ask_question "Could you give me the worker name used from $poolname ? " poolworkername
_ask_question "Could you give me the worker password for $poolworkername from $poolname ? " poolworkerpassword
}

_noregistration_server_pool () {
_server_pool_basics_question
}

_ask_server_pool () {
_ask_question "Do you wan to use a mining server pool which needs registration to mine ? [y/n] " answer
echo $answer
if [ "$answer" == "y" ]; then
	registration="yes"
	_registration_server_pool
else
	_noregistration_server_pool
fi
}

#START
_easy_mode_wizard
