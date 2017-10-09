#!/bin/bash
clear
# VARIABLES
version=0.02

# FUNCTIONS
_intro ()
{
echo
echo "Welcome to PastaMiner v$version ! (with cpuminer-multi)"
echo
echo "Coins supported :"
echo "- XMR (Monero)"
}

_ask_coin ()
{
echo "(Alt)coins available :"
echo
echo "1) XMR (Monero)"
echo "2) DOGE (Dogecoin)"
echo
read -p "Which (alt)coin do you want to mine ? : " coin
case "$coin" in
	1 ) _default_pool_server XMR;;
	2 ) _default_pool_server DOGE;;
esac
}

_default_pool_server ()
{
if [ "$1" == "XMR" ]; then
	defaultserverpool="pool.minexmr.com"
	ports="7777"
	serverpoolpassword="x"
	coin="XMR"
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

_ask_resume ()
{
echo "With the info you gave me, I can resume the miner with this settings :"
echo
echo "(Alt)coin : $coin"
echo "Server pool URL : $serverpool"
echo "Server pool port(s) : $ports"
echo "Server pool password : $serverpoolpassword"
echo "Your wallet : $wallet"
echo
_ask_question_yn "All of this information are correct ? [y/n] "
}

_easy_mode_wizard ()
{
_ask_coin
echo "$coin is a good choice !"
echo
_ask_server_pool
echo
_ask_wallet
echo
_ask_resume
}

_back_to_begin ()
{
clear && _check_flag_folder && _intro && _check_cpuminer && _main_menu
}

_main_menu ()
{
echo
echo "1) Add miner wizard"
echo "2) Manage miner (start/stop/delete)"
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
	2 );;
	3 );;
	8 );;
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
else
	echo
	echo "[DEBUG] cpuminer-multi IS installed !"
fi
}

# MAIN MENU
_check_flag_folder
_intro
_check_cpuminer
_main_menu
