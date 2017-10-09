#!/bin/bash
clear
# VARIABLES
version=0.01

# FUNCTIONS
_intro ()
{
echo
echo "Welcome to PastaMiner v$version ! (with cpuminer-multi)"
echo
echo "Coins supported :"
echo "- XMR (Monero)"
}

_back_to_begin ()
{
clear && _check_flag_folder && _intro && _check_cpuminer && _main_menu
}

_main_menu ()
{
echo
echo "1) Add miner (easy/advanced)"
echo "2) Manage miner (start/stop/delete)"
echo "3) Enable Plex Stream Watch"
echo
echo "8) Update PastaMiner_cpuminer-multi"
echo "9) Uninstall PastaMiner_cpuminer-multi"
echo "0) Quit"
echo
read -p "What do you want to do ? " choice
case "$choice" in
	1 );;
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
