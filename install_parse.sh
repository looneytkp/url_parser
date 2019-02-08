#!/bin/bash
#looneytkp
set -ex
version="v6.60"

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
		cp {changelog,.conf,.date,.help,install_parse.sh,parse.sh} "$directory"
		cd - > /dev/null;date +%m-%d > .date
		echo -e "$name $version: installed."; $name -h
	fi
else
	if [ -d url_parser ]; then cd url_parser; fi
	a=$(md5sum "$_script"|sed "s:  .*$name.sh::")
	b=$(md5sum "$inst_dir"|sed "s:  $inst_dir::")
	if [[ "$a" != "$b" ]]; then $name -c
		printf %b "                 > to $name $version.\\r"
		read -n 1 -erp "update? Y/n: " update
		case $update in
			Y|y|'')
				sudo cp -u "$_script" "$inst_dir";sudo chmod 777 "$inst_dir"
				cp -u {changelog,.conf,.date,.help,install_parse.sh,parse.sh} "$directory"
				cd - > /dev/null;date +%m-%d > .date
				echo -e "$name updated.";exit 0;;
			n) echo "$name: not updated.";date +%m-%d > .date;return;;
		esac
	else
		x=$(cat install_parse.sh changelog .conf .date .help|md5sum)
		y=$(cat "$directory"/install_parse.sh "$directory"/changelog "$directory"/.conf "$directory"/.date "$directory"/.help|md5sum)
		if [ "$x" != "$y" ];then
			cp -u {install_parse.sh,changelog,.conf,.date,.help} "$directory"
			echo -e "components updated.\\n$name: up-to-date -- $version."
		else
			echo -e "$name: up-to-date -- $version."
		fi
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
name="parse";_script=$name.sh
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
	run
fi
