#!/bin/bash
set -e
if [ ! -e /usr/bin/xclip ]&&[ ! -e /usr/local/bin/xclip ]; then
	echo -e "install xclip.";exit 0
elif [ ! -e /usr/bin/wget ]&&[ ! -e /usr/local/bin/wget ]; then
	echo -e "install wget.";exit 0
elif [ ! -e /usr/bin/git ]&&[ ! -e /usr/local/bin/git ]; then
	printf "git is not installed."
	if [ $arch == Darwin ]; then
		read -erp " install git ? Y/n: " gitInst
		case $gitInst in
			Y|y|'') git --version;;
			n) echo "git is essential for this to run.";exit 0;;
		esac
	fi
fi
version="v6.55"
name="parse"
_script=parse.sh
directory=~/.parseHub
if [ ! -d $directory ]; then mkdir $directory;fi
arch=$(uname)
if [ "$arch" = Linux ]; then inst_dir=/usr/bin/$name
elif [ "$arch" = Darwin ]; then inst_dir=/usr/local/bin/$name
fi
cd $directory

if [ -e $_script ]; then
	if [[ ! -e $inst_dir ]]; then
		sudo cp "$_script" $inst_dir && sudo chmod 777 $inst_dir
		echo -e "$name $version: installed.";$name -c
	else
#		if [ "$0" == $inst_dir ]; then
#			echo -e "$name: $version already installed."
#			exit 0
#		fi
		a=$(md5sum "$_script"|sed "s:  .*$name.sh::")
		b=$(md5sum $inst_dir|sed "s:  $inst_dir::")
		if [[ "$a" != "$b" ]]; then
			sudo cp -u "$_script" $inst_dir;sudo chmod 777 $inst_dir
			echo -e "$name: updated to $version.";$name -c
		else
			echo -e "$name: up-to-date -- $version."
		fi
	fi
else
	git clone https://github.com/looneytkp/url_parser.git 2> /dev/null
	cd url_parser
	bash install.sh
	exit
fi
