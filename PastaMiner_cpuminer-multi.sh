#!/bin/bash
# VARIABLES
version=0.02
#workers=$(screen -ls | grep "pastaminer" | cut -d . -f2 | cut -d "(" -f1)

# FUNCTIONS
_intro ()
{
echo
echo "Welcome to PastaMiner v$version ! (with cpuminer-multi)"
echo
echo "Coins supported :"
echo "- XMR (Monero)"
echo
}

_fail () {
echo -e "\e[31mWrong input !\e[39m"
}

_return () {
echo
echo -e "\e[33mBack to main menu in 3sec...\e[39m"
sleep 3
_root
}

_worker_status_widget () {
#workers=$(screen -ls | grep "pastaminer" | cut -d . -f2 | cut -d "(" -f1)
workers=$(cat workers.conf | grep "pastaminer-" | cut -f1 -d";")
if [ ! "$workers" == "" ]; then
	echo "Worker Name              State           Coin    Server Pool             CPU Threads "
	echo "-------------------------------------------------------------------------------------"
	for worker in $workers; do
		_check_state $worker
		_get_worker_conf $worker
		echo "| $workername	| $state	| $coin	| $serverpool	| $cputhreads	    |"
		echo "-------------------------------------------------------------------------------------"
	done
else
	echo "There is no active worker."
fi
}

_check_state () {
if [[ $(screen -ls) == *"$1"* ]]; then
	state=$(echo -e "\e[32mRUNNING\e[39m")
	running="yes"
else
	state=$(echo -e "\e[31mNOT RUNNING\e[39m")
	running="no"
fi
#echo "$1 is $state"
}

_ask_coin ()
{
echo "(Alt)coins available :"
echo
echo "1) XMR (Monero)"
echo "2) DOGE (Dogecoin)"
echo "0) Back to the main menu"
echo
read -p "Which (alt)coin do you want to mine ? : " coin
case "$coin" in
	1 ) _default_pool_server XMR;;
	2 ) _default_pool_server DOGE;;
	0 ) _root;;
	* ) _fail;echo;${FUNCNAME[0]};;
esac
}

function _ask_worker_action () {
_check_state $1
echo
if [ "$running" == "no" ]; then
	echo "1) Start worker"
	echo "3) Delete worker"
	echo "0) Back to the main menu"
else
	echo "2) Stop worker"
	echo "3) Delete worker"
	echo "0) Back to the main menu"
fi
echo
read -p "What do you want to do for $workerchoicename ? " workeraction
_worker_action
}

_worker_action () {
case "$workeraction" in
	1 ) _start_worker $workerchoicename;;
	2 ) _stop_worker $workerchoicename;;
	3 ) _ask_delete_worker $workerchoicename;;
	0 ) _root;;
	* ) _fail;_ask_worker_action;;
esac
}

#_get_workers_list () {
#workers=$(cat workers.conf | grep "pastaminer-" | cut -f1 -d";")
#
#}

_get_worker_conf () {
while IFS='' read -r line || [[ -n "$line" ]]; do
	if [[ "$line" == *"$1"* ]]; then
		workerconf=$line
	fi
done < workers.conf
workername=$(echo $workerconf | cut -f1 -d";")
coin=$(echo $workerconf | cut -f2 -d";")
cputhreads=$(echo $workerconf | cut -f3 -d";")
serverpool=$(echo $workerconf | cut -f4 -d";")
algorithm=$(echo $workerconf | cut -f5 -d";")
ports=$(echo $workerconf | cut -f6 -d";")
poolpassword=$(echo $workerconf | cut -f7 -d";")
wallet=$(echo $workerconf | cut -f8 -d";")
}

_ask_manage_worker () {
workers_array=()
workers=$(cat workers.conf | grep "pastaminer-" | cut -f1 -d";")
if [ "$workers" == "" ]; then
	echo "You don't have any worker, let's create one !"
	#_easy_mode_wizard
	#_read_workers_conf
fi
for worker in $workers;
do
	#echo "Ajout de $worker au tableau"
	workers_array+=($worker)
	#echo "Ajouté"
done
echo "List of your workers :"
for index in "${!workers_array[@]}"; do
	indexplus1=$(( $index+1 ))
	echo "$indexplus1) ${workers_array[index]}"
done
echo
read -p "Which worker do you want to manage ? : " workerchoice
indexminus1=$(($workerchoice-1))
if [ "$workerchoice" == "" ]; then
	echo "No value selected"
else
	echo "You choose ${workers_array[$indexminus1]}"
	workerchoicename="${workers_array[$indexminus1]}"
	_ask_worker_action $workerchoicename
fi
}

_ask_nb_threads () {
nbproc=$(nproc)
echo "You currently have $nbproc CPU that can be dedicated to your workers"
echo
echo "BE CAREFUL, surallocating threads is dangerous for your system !"
echo "=> DO NOT exceed $nbproc (PastaMiner will not permit it)"
echo "=> For safety, allocate $nbproc-1 threads to let your system breath a bit :)"
echo
read -p "How many threads do you want to allocate to your worker ? " nbthreads
echo "Ok, $nbthreads seems good !"
}

_default_pool_server ()
{
if [ "$1" == "XMR" ]; then
	defaultserverpool="pool.minexmr.com"
	ports="4444,5555"
	serverpoolpassword="x"
	coin="XMR"
	algorithm="cryptonight"
	skippwd="yes"
fi
if [ "$1" == "DOGE" ]; then
	defaultserverpool="eu.multipool.us"
	coin="DOGE"
fi
}

_ask_wallet ()
{
read -p "Could you give me your wallet please ? : " wallet
echo "Thanks"
}

_ask_server_pool_password ()
{
if [ "$skippwd" == "" ]; then
	read -p "Could you give me the server pool password if needed ? (if no password, press ENTER)" serverpoolpassword
	echo "Thanks for the password."
else
	echo "Password already known."
fi
}

_ask_server_pool_port ()
{
read -p "Could you give me the port(s) ( ie 4444 or 4444,5555 ) please ? : " ports
echo "Thanks"
}

_ask_server_pool_name ()
{
read -p "Could you give the pool server name URL (ie : pool.serverpool.com ) please ? : " serverpool
echo "Thanks"
}

_ask_server_pool ()
{
_ask_question_yn "Do you want to set a custom mining pool ? (you will also need to know the PORTS) [y/n] "
if [ "$answer" == "y" ]; then
	_ask_server_pool_name
	echo
	_ask_server_pool_port
else
	echo "We will use $defaultserverpool for mining ;)"
	serverpool=$defaultserverpool
fi
echo
_ask_server_pool_password
}

_save_worker () {
if [ "$answer" == "y" ]; then
echo "Saving the worker configuration localy..."
cat >>workers.conf <<EOL
$workername;$coin;$nbthreads;$serverpool;$algorithm;$ports;$serverpoolpassword;$wallet
EOL
fi
}

_ask_resume ()
{
echo "With the info you gave me, I can resume the miner with this settings :"
echo
echo "(Alt)coin : $coin"
echo "CPU threads : $nbthreads"
echo "Server pool URL : $serverpool"
echo "Coin algorithm : $algorithm"
echo "Server pool port(s) : $ports"
echo "Server pool password : $serverpoolpassword"
echo "Your wallet : $wallet"
echo "Worker name : $workername"
echo
_ask_question_yn "All of this information are correct ? [y/n] "
_save_worker
}

_check_screen ()
{
if [[ $(screen -ls) == *"$1"* ]]; then
	echo "Worker already screened !"
	screened=1
else
	echo "Worker not screened yet !"
	screened=0
fi
}

_start_worker ()
{
_get_worker_conf $1
worker_screen_list=$(screen -ls)
echo "Starting worker $1..."
screen -dmS $1 ./cpuminer-multi/cpuminer -a $algorithm -o stratum+tcp://$defaultserverpool:$ports -u $wallet -p $serverpoolpassword -t $nbthreads
echo
if [[ $(screen -ls) == *"$1"* ]]; then
	echo -e "[\e[32mSUCCESS\e[39m] $1 has been started !"
else
	echo "[ERROR] $1 has NOT been started !"
fi
_return
}

_stop_worker () {
workers=$(screen -ls | grep "pastaminer" | cut -d . -f2 | cut -d "(" -f1)
if [[ "$workers" == *"$1"* ]]; then
	echo
	echo "$1 has been found."
	echo "Killing it..."
	screen -X -S $1 kill
	echo
	if [ ! "$workers" == *"$1"* ]; then
		echo -e "[\e[32mSUCCESS\e[39m] $1 has been stopped !"
	else
		echo "[ERROR] I can't kill it !"
	fi
else
echo "There is no ACTIVE worker called $1"
fi
_return
}

_ask_delete_worker () {
echo
_ask_question_yn "Are you really sure to delete $1 ? [y/n]"
_delete_worker
}

_delete_worker () {
echo
if [ "$answer" == "y" ]; then
	echo "Checking if $1 is currently running..."
	_stop_worker $1
else
	echo "Nothing to do."
	_back_to_begin
fi
sleep 5
_back_to_begin
}

_ask_worker_name ()
{
UUID=$RANDOM
read -p "How do you want to name your worker ? (if not pastaminer-$UUID-$coin will be used)" workername
if [ "$workername" == "" ]; then
	workername="pastaminer-$UUID-$coin"
	echo "So let's use $workername"
else
	echo "What a beautiful name ! "
fi
}

_create_worker ()
{
if [ "$answer" == "y" ]; then
	echo "Checking if $1 currently existing..."
elif [ "$screened" == "0" ]; then
	echo "No !"
	echo "Creating worker..."
	_start_worker $1
else
	echo "Worker $1 already started !"
fi
}

_easy_mode_wizard ()
{
_ask_coin
echo "$coin is a good choice !"
echo
_ask_nb_threads
echo
_ask_server_pool
echo
_ask_wallet
echo
_ask_worker_name
echo
_ask_resume
echo
_start_worker $workername
}

#_back_to_begin ()
#{
#_main_menu
#clear && _check_flag_folder && _intro && _check_cpuminer && _main_menu
#}

_main_menu ()
{
echo
echo "Available tasks :"
echo
echo "1) Add worker wizard"
echo "2) Manage worker (start/stop/delete)"
echo "3) Enable Plex Stream Watch"
echo
echo "7) Reinstall cpuminer-multi from latest updates"
echo "8) Update PastaMiner_cpuminer-multi"
echo "9) Uninstall PastaMiner_cpuminer-multi"
echo "0) Quit"
echo
read -p "What do you want to do ? " choice
case "$choice" in
	1 ) echo;_easy_mode_wizard;;
	2 ) echo;_ask_manage_worker;;
	3 ) echo "Not implemented yet.";sleep 3;_root;;
	8 ) echo "Not implemented yet.";sleep 3;_root;;
	9 ) _uninstall_pastaminer;;
	0 ) echo "See you! Bye.";echo;exit;;
	* ) _back_to_begin;;
esac
echo

}

_uninstall_pastaminer ()
{
echo
_ask_question_yn "Would you like to uninstall PastaMiner_cpuminer-multi ? [y/n] "
if [ "$answer" == "y" ]; then
	echo "Uninstalling PastaMiner_cpuminer-multi..."
	rm -rf .flags cpuminer-multi
	echo "PastaMiner_cpuminer-multi uninstalled !"
	_back_to_begin
else
	_back_to_begin
fi
}

_check_flag_folder ()
{
if [ ! -d .flags ]; then
	mkdir .flags
fi
}

_ask_question_yn ()
{
read -p "$1" answer
echo
}

#_download_cpuminer ()
#{
#if [ "$answer" == "y" ]; then
#	echo "Downloading cpuminer-multi..."
#	git clone --quiet https://github.com/tpruvot/cpuminer-multi.git
#	touch .flags/.downloaded
#	echo "Downloaded !"
#else
#	exit
#fi
#}

_install_cpuminer ()
{
if [ "$answer" == "y" ]; then
	echo "Installing dependencies..."
	sudo apt-get install -y -qq automake autoconf pkg-config libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev make g++
	echo "Downloading cpuminer-multi..."
	git clone --quiet https://github.com/tpruvot/cpuminer-multi.git
	echo "Installing cpuminer-multi..."
	cd cpuminer-multi
	./build.sh >/dev/null 2>&1
	cd ..
	touch .flags/.installed
	_back_to_begin
else
	echo "Too bad, exiting."
	echo
	exit
fi
}

_check_cpuminer ()
{
#if [ ! -f .flags/.downloaded ]; then
#	echo
#	echo "cpuminer-multi not downloaded !"
#	_ask_question_yn "Do you want to download it ? [y/n] "
#	_download_cpuminer
#else
#	echo "[DEBUG] cpuminer-multi downloaded !"
#fi
if [ ! -f .flags/.installed ]; then
	echo
	echo ">>> cpuminer-multi is not installed !"
	echo
	_ask_question_yn "Do you want to install it ? [y/n] "
	_install_cpuminer
#else
	#echo
	#echo "[DEBUG] cpuminer-multi IS installed !"
fi
}

_root () {
# MAIN MENU
clear
_check_flag_folder
_intro
_worker_status_widget
_check_cpuminer
_main_menu
}

_root
