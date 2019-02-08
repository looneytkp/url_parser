#!/bin/bash
#looneytkp
set -e

connect(){
	echo "no internet connection."
	if [ -z "$(ls -A "$directory")" ]; then rm -rf "$directory";fi
	exit
}

abort(){
	if [ -d url_parser ];then
		if [ ! -e url_parser/install_parse.sh ]; then
			rm -rf "$directory"
		fi
	else
		rm -rf "$directory"
	fi
}

run() {
if [[ ! -e $inst_dir ]]; then
	sudo cp "$_script" "$inst_dir" && sudo chmod 777 "$inst_dir"
	if [ $? != 0 ]; then
		rm -rf "$directory"
		echo "$name not installed."
	else
		date +%m-%d > .date
		echo -e "$name $version: installed."; $name -h
	fi
else
	a=$(md5sum "$_script"|sed "s:  .*$name.sh::")
	b=$(md5sum "$inst_dir"|sed "s:  $inst_dir::")
	if [[ "$a" != "$b" ]]; then
		bash changelog
		printf %b "                 > $name $version available.\\r"
		read -n 1 -erp "update? Y/n: " update
		case $update in
			Y|y|'')
				sudo cp -u "$_script" "$inst_dir";sudo chmod 777 "$inst_dir"
				date +%m-%d > .date
				echo -e "$name updated.";exit 0;;
			n) echo "$name: not updated.";date +%m-%d > .date;return;;
		esac
	else
		echo -e "$name: up-to-date -- $version."
		date +%m-%d > .date
	fi
fi
}

trap abort SIGINT
if [ "$arch" == Darwin ]; then
	if [ ! -e /usr/bin/pbcopy ]; then echo -e "install pbcopy.";exit 0
	elif [ ! -e /usr/local/bin/wget ]; then echo "install wget.";exit 0
	elif [ ! -e /usr/local/bin/git ]; then printf "git is not installed."
		read -erp " install git ? Y/n: " gitInst
		case $gitInst in
			Y|y|'') git --version;;
			*) echo "git is essential for parse to run.";exit 0;;
		esac
	fi
elif [ "$arch" == Linux ]; then
	if [ ! -e /usr/bin/xclip ]; then echo -e "install xclip.";exit 0
	elif [ ! -e /usr/bin/wget ]; then echo -e "install wget.";exit 0
	elif [ ! -e /usr/bin/git ]; then echo "install git.";exit 0
	fi
fi	
version="v6.60b";name="parse";_script=$name.sh
arch=$(uname)
if [ "$arch" = Linux ]; then inst_dir=/usr/bin/$name
elif [ "$arch" = Darwin ]; then inst_dir=/usr/local/bin/$name
fi
directory=~/.parseHub
if [ ! -d $directory ]; then mkdir $directory;fi
if [ "$PWD" != "$directory" ]; then cd $directory; fi
if [ ! -d url_parser ]; then
	echo "installing..."
	git clone -q https://github.com/looneytkp/url_parser.git 2> /dev/null||connect
	cd url_parser
	run
elif [ -z "$(ls -A url_parser)" ]; then
	rm -rf url_parser
	echo "installing..."
	git clone -q https://github.com/looneytkp/url_parser.git 2> /dev/null||connect
	cd url_parser
	run
else
	cd url_parser
	git pull -q 2> /dev/null||connect
	run
fi
