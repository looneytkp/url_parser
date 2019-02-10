#!/bin/bash
#looneytkp
set -e
version="v6.65"

connect(){
	echo "no internet connection."
	if [ -z "$(ls -A "$directory")" ]; then rm -rf "$directory";fi
	return 1
}

abort(){
	if [ -d "$directory"/url_parser ];then
		if [ ! -e "$directory"/url_parser/install_parse.sh ]; then
			rm -rf "$directory"
		fi
	else
		rm -rf "$directory"
	fi
	exit 0
}

run() {
if [[ ! -e $inst_dir ]]; then
	if ! sudo cp -u "$_script" "$inst_dir" && sudo chmod 777 "$inst_dir"; then
		rm -rf "$directory"
		echo "$name not installed."
	else
		cp {changelog,.conf,.date,.help,install_parse.sh,parse.sh} "$directory"
		cd - > /dev/null;date +%m-%d > .date
		echo -e "$name $version: installed."; $name -h
	fi
else
	a=$(md5sum "$_script"|sed "s:  .*$name.sh::")
	b=$(md5sum "$inst_dir"|sed "s:  $inst_dir::")
	auto=$(grep "AUTOMATIC_UPDATE=" "$directory"/.conf|sed "s/AUTOMATIC_UPDATE=//")
	if [[ "$a" != "$b" ]]; then $name -c
		if [ "$auto" == NO ]; then
			printf %b "                 > to $name $version.\\r"
			read -n 1 -erp "update? Y/n: " update
		else
			update=y
		fi
		case $update in
			Y|y|'')
				sudo cp -u "$_script" "$inst_dir";sudo chmod 777 "$inst_dir"
				cp -u {parse.sh,install_parse.sh,changelog,.help} "$directory"
				cd - > /dev/null;date +%m-%d > .date
				echo -e "$name & components updated.";return 5;;
			n|*) echo "$name: not updated.";cd - > /dev/null;date +%m-%d > .date;return 5;;
		esac
	else
		x=$(cat install_parse.sh changelog .help|md5sum)
		y=$(cat "$directory"/install_parse.sh "$directory"/changelog "$directory"/.help|md5sum)
		if [ "$x" != "$y" ];then
			cp -u {install_parse.sh,changelog,.help} "$directory"
			echo -e "components updated.\\n$name: up-to-date -- $version.";return 5
		else
			echo -e "$name: up-to-date -- $version."
		fi
		cd - > /dev/null;date +%m-%d > .date
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
if [ ! -d $directory ]; then
	mkdir $directory;cd $directory
	echo "installing..."
	git clone -q https://github.com/looneytkp/url_parser.git 2> /dev/null||connect
	cd url_parser
	run && exit
fi
if [ "$PWD" != "$directory" ]; then cd $directory;fi

if [ -e $inst_dir ]&&[ -d "$directory" ]&&[ -d "$directory"/url_parser ];then
	if [ "$0" != url_parser/install_parse.sh ]; then exit 0;fi
fi

if [ ! -d url_parser ]; then
	if [ "$r" == -r ]; then echo "installing...";fi
	git clone -q https://github.com/looneytkp/url_parser.git 2> /dev/null||connect
	cd url_parser
	run && exit
elif [ -z "$(ls -A url_parser)" ]; then
	rm -rf url_parser
	if [ "$r" == -r ];then echo "installing...";fi
	git clone -q https://github.com/looneytkp/url_parser.git 2> /dev/null||connect
	cd url_parser
	run
else
	cd url_parser
	run
fi
#end of script
