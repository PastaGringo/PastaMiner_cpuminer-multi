#!/bin/bash
# VARIABLES
version=0.03

_line_title () {
echo "********** $1 **********"
}

#NEW WIZARD
_ask_resume () {
echo
_line_title "Résumé"
echo "Coin : $coin"
echo "Worker Name : $workername"
echo "CPU threads : $nbthreads"
echo "Algorithm : $algorithm"
echo "Pool Name : $poolname"
echo "Pool URL : $poolserverurl"
echo "Pool ports : $poolserverports"
#echo "Wallet : $wallet"
echo "Registered ? $registration"
if [ "$registration" == "yes" ]; then
	echo "Pool User Account : $poolusername"
	echo "Pool worker password : $poolworkerpassword"
else
	echo "Pool server password : $poolserverpassword"
	echo "Wallet : $wallet"
fi
_ask_question "Is it OK ? [y/n] => " answer
_save_worker
}

_easy_mode_wizard () {
_ask_coin
_ask_nb_threads
echo
_ask_worker_name
_ask_server_pool
echo
_ask_resume
echo
_start_worker $workername
}

_ask_question () {
echo
read -p "$1" $2
}

_server_pool_basics_question () {
_ask_question "What is the miner server pool name ? (ie : "MineXMR" or "AikaPool") => " poolname
_ask_question "What is the miner server pool URL ? (ie : "pool.minexmr.com" or "stratum.aikapool.com" or etc.) => " poolserverurl
_ask_question "What is the port(s) used for miner server pool ? (ie : "7777" or "7938" or etc.) => " poolserverports
}

_registration_server_pool () {
_ask_question "Could you give me your USERNAME used on $poolname ? => " poolusername
_ask_question "Could you give me the WORKER PASSWORD for $workername from $poolname ? => " poolworkerpassword
}

_noregistration_server_pool () {
_ask_wallet
_ask_question "Could you give me the server pool password if needed ? (if you don't want, please press ENTER)" poolserverpassword
}

_ask_server_pool () {
_ask_question "Do you wan to use a mining server pool which needs registration to mine ? [y/n] " answer
if [ "$answer" == "y" ]; then
	registration="yes"
	_server_pool_basics_question
	_registration_server_pool
else
	registration="no"
	_server_pool_basics_question
	_noregistration_server_pool
fi
}
#END NEW WIZARD

# FUNCTIONS
_intro ()
{
echo
echo "Welcome to PastaMiner v$version ! (with cpuminer-multi)"
echo
echo "Coins supported : XMR - DOGE - XVG - BTC"
echo
_check_plex_streams_watch
}

_check_plex_streams_watch () {

if [ -f .flags/.plex_streams_watch_enabled ]; then
	echo "PLEX STREAMS WATCH ENABLED !"
	echo
else
	echo "PLEX STREAMS WATCH DISABLED !"
	echo
fi
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
workers=$(cat workers.conf | grep "pastaminer-" | cut -f1 -d";")
if [ ! "$workers" == "" ]; then
	echo "Worker Name              State           Coin    Server Pool    CPU Threads "
	echo "-----------------------------------------------------------------------------"
	for worker in $workers; do
		_check_state $worker
		_get_worker_conf $worker
		echo "| $workername	| $state	| $coin	| $poolname	| $cputhreads	    |"
		echo "-----------------------------------------------------------------------------"
	done
else
	echo -e "\e[1;4mThere is no active worker\e[39m"
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
#echo "--------------------------------------------------------------------------"
#echo "				(Alt)coins available :				"
#echo "--------------------------------------------------------------------------"
_line_title "(Alt)coins available :"
echo
echo "1) XMR (Monero)"
echo "2) DOGE (Dogecoin)"
echo "3) BCN (Bytecoin)"
echo "4) XVG (Vedge)"
echo "5) VTC (VertCoin)"
echo
echo "0) Back to the main menu"
echo
read -p "Which (alt)coin do you want to mine ? (choose a number) => " coin
case "$coin" in
	1 ) _default_pool_server XMR;;
	2 ) _default_pool_server DOGE;;
	3 ) _default_pool_server BCN;;
	4 ) _default_pool_server XVG;;
	5 ) _default_pool_server VTC;;
	0 ) _root;;
	* ) _fail;echo;${FUNCNAME[0]};;
esac
echo
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
	1 ) _ask_question_yn "Are you sure to start the worker $workerchoicename ? [y/n] => ";_start_worker $workerchoicename;;
	2 ) _stop_worker $workerchoicename;;
	3 ) _ask_delete_worker $workerchoicename;;
	0 ) _root;;
	* ) _fail;_ask_worker_action;;
esac
}

_get_worker_conf () {
while IFS='' read -r line || [[ -n "$line" ]]; do
	if [[ "$line" == *"$1"* ]]; then
		workerconf=$line
	fi
done < workers.conf
workername=$(echo $workerconf | cut -f1 -d";")
registration=$(echo $workerconf | cut -f2 -d";")
cputhreads=$(echo $workerconf | cut -f3 -d";")
coin=$(echo $workerconf | cut -f4 -d";")
algorithm=$(echo $workerconf | cut -f5 -d";")
poolname=$(echo $workerconf | cut -f6 -d";")
poolserverurl=$(echo $workerconf | cut -f7 -d";")
poolserverports=$(echo $workerconf | cut -f8 -d";")
if [ $(echo $workerconf | cut -f2 -d";") == "y" ]; then
	poolusername=$(echo $workerconf | cut -f9 -d";")
	poolworkerpassword=$(echo $workerconf | cut -f10 -d";")
else
	poolserverpasswrd=$(echo $workerconf | cut -f9 -d";")
	wallet=$(echo $workerconf | cut -f10 -d";")
fi
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
echo "----------------------------------------------------------------------------"
echo "You currently have $nbproc CPU that can be dedicated to your workers"
echo "BE CAREFUL, surallocating threads is dangerous for your system !"
echo "=> DO NOT exceed $nbproc (PastaMiner will not permit it)"
echo "=> For safety, allocate $nbproc-1 threads to let your system breath a bit :)"
echo "----------------------------------------------------------------------------"
echo
read -p "How many threads do you want to allocate to your worker ? (entrer a number) => " nbthreads
echo "Ok, $nbthreads seems good !"
}

_default_pool_server ()
{
if [ "$1" == "XMR" ]; then
	defaultpoolname="MineXMR"
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
if [ "$1" == "BCN" ]; then
	defaultserverpool="stratum.aikapool.com"
fi
if [ "$1" == "XVG" ]; then
	coin="XVG"
	algorithm="scrypt"
fi
if [ "$1" == "VTC" ]; then
	coin="VTC"
	algorithm="lyra2REv2"
fi
}

_ask_wallet ()
{
echo
_line_title "$coin WALLET"
echo
read -p "Could you give me your wallet (OR EMAIL) please ? : " wallet
echo "Thanks"
}

_ask_server_pool_password ()
{
if [ "$skippwd" == "" ]; then
	read -p "Could you give me the server pool password if needed ? (if you don't want, please press ENTER)" serverpoolpassword
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

_ask_server_pool_user_password () {
_ask_question_yn "Does the server mining pool force to have a registered account to mine ? [y/n] => "
if [ "$answer" == "yes" ]; then
	ask_server_pool_username
	ask_server_pool_password
else
	echo "Ouf."
fi
}

_save_worker_with_account () {
echo "[DEBUG] $workername;$registration;$nbthreads;$coin;$algorithm;$poolname;$poolserverurl;$poolserverports;$poolusername;$poolworkerpassword"
cat >>workers.conf <<EOL
$workername;$registration;$nbthreads;$coin;$algorithm;$poolname;$poolserverurl;$poolserverports;$poolusername;$poolworkerpassword
EOL
}

_save_worker_without_account () {
echo "[DEBUG] $workername;$registration;$nbthreads;$coin;$algorithm;$poolname;$poolserverurl;$poolserverports;$poolserverpassword;$wallet"
cat >>workers.conf <<EOL
$workername;$registration;$nbthreads;$coin;$algorithm;$poolname;$poolserverurl;$poolserverports;$poolserverpassword;$wallet
EOL
}

_save_worker () {
if [ "$answer" == "y" ]; then
echo "Saving the worker configuration localy..."
echo "[DEBUG] Registration = $answer"
	if [ "$registration" == "y" ]; then
		_save_worker_with_account
	else
		_save_worker_without_account
	fi
else
	echo "[_SAVE_WORKER] Maybe another time ;)"
fi
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
if [ "$answer" == "y" ]; then
	echo
	_get_worker_conf $1
	worker_screen_list=$(screen -ls)
	echo "Starting worker $1..."
	#echo "[DEBUG] registration = $registration"
	if [ ! "$registration" == "yes" ]; then
	#echo "screen -dmS $1 ./cpuminer-multi/cpuminer -a $algorithm -o stratum+tcp://$poolserverurl:$poolserverports -u $wallet -p $poolserverpassword -t $nbthreads"
	screen -dmS $1 ./cpuminer-multi/cpuminer -a $algorithm -o stratum+tcp://$poolserverurl:$poolserverports -u $wallet -p $poolserverpassword -t $nbthreads
	#echo "$1 $algorithm $poolserverurl $poolserverports $wallet $poolserverpassword $nbthreads"
	else
	#echo $algorithm
	#echo "screen -dmS $1 ./cpuminer-multi/cpuminer -a $algorithm -o stratum+tcp://$poolserverurl:$poolserverports -u $poolusername.$1 -p $poolworkerpassword -t $nbthreads"
	screen -dmS $1 ./cpuminer-multi/cpuminer -a $algorithm -o stratum+tcp://$poolserverurl:$poolserverports -u $poolusername.$1 -p $poolworkerpassword -t $nbthreads
	fi
	echo
	if [[ $(screen -ls) == *"$1"* ]]; then
		echo -e "[\e[32mSUCCESS\e[39m] $1 has been started !"
	else
		echo "[ERROR] $1 has NOT been started !"
	fi
	_return
else
	echo "Maybe next time !"
	_return
fi
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
if [ ! "$removing" == "yes" ]; then
_return
fi
}

_ask_delete_worker () {
echo
_ask_question_yn "Are you really sure to delete $1 ? [y/n] "
_delete_worker $1
}

_delete_worker () {
if [ "$answer" == "y" ]; then
	echo "Checking if $1 is currently running..."
	_check_state $1
	if [ "$running" == "yes" ]; then
		removing="yes"
		_stop_worker $1
	else
		echo "$1 is not running !"
	fi
	echo
	echo -e "\e[33mDeleting worker $1...\e[39m"
	sed -i "/$1/d" workers.conf
	echo
	echo -e "[\e[32mSUCCESS\e[39m] $1 has been deleted !"
	_return
else
	echo "Nothing to do."
	_return
fi
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

_plex_streams_watch_enable () {
echo
echo "Activating Plex Streams Watch..."
touch .flags/.plex_streams_watch_enabled
if [ -f .flags/.plex_streams_watch_enabled ]; then
	echo "Plex Streams Wtach enabled !"
else
	echo "Can't enable Plex Streams Watch !"
fi
_return
}

_plex_streams_watch_disable () {
echo
echo "Deactivating Plex Stream Watch..."
if [ -f .flags/.plex_streams_watch_enabled ]; then
	rm .flags/.plex_streams_watch_enabled
	echo "Plex Streams Wtach has been disabled !"
fi
_return
}

_main_menu ()
{
echo
echo "Available tasks :"
echo
echo "1) Add worker wizard"
echo "2) Manage worker (start/stop/delete)"
echo "3) Enable Plex Streams Watch"
echo "4) Disable Plex Streams Watch"
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
	3 ) _plex_streams_watch_enable;;
	4 ) _plex_streams_watch_disable;;
	8 ) echo "Not implemented yet.";sleep 3;_root;;
	9 ) _uninstall_pastaminer;;
	0 ) echo "See you! Bye.";echo;exit;;
	* ) _return;;
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
	_return
else
	_return
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
