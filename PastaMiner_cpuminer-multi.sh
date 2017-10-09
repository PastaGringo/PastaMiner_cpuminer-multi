#!/bin/bash
clear
# FUNCTIONS
_main_menu ()
{
echo
echo "Welcome to PastaMiner v2 ! (with cpuminer-multi)"
echo
echo "What do you want to do ?"
echo
}

_create_flag_folder ()
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

_download_cpuminer ()
{
if [ "$answer" == "y" ]; then
	echo "Downloading cpuminer-multi..."
	git clone --quiet https://github.com/LucasJones/cpuminer-multi
	touch .flags/.downloaded
	echo "Downloaded !"
else
	exit
fi
}

_install_cpuminer ()
{
if [ "$answer" == "y" ]; then
	echo "Installig cpuminer-multi..."
	cd  cpuminer-multi
	echo "Autogen..."
	./autogen.sh > /dev/null
	echo "Configuring..."
	./configure CFLAGS="-march=native"
	echo "Making..."
	make > /dev/null
	cd ..
	touch .flags/.installed
	echo
	echo "cpuminer-multi installed !"
	clear
fi
}

_check_cpuminer ()
{
if [ ! -f .flags/.downloaded ]; then
	echo "cpuminer-multi not downloaded !"
	_ask_question_yn "Do you want to download it ? "
	_download_cpuminer
else
	echo "cpuminer-multi downloaded !"
fi
if [ ! -f .flags/.installed ]; then
	echo "cpuminer-multi not built !"
	_ask_question_yn "Do you want to build it ? "
	_install_cpuminer
else
	echo "cpuminer-multi built !"
fi
}

# MAIN MENU
_create_flag_folder
_check_cpuminer
_main_menu
