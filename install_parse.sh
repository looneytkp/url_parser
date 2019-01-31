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

run() {
if [[ ! -e $inst_dir ]]; then
	sudo cp "$_script" $inst_dir && sudo chmod 777 $inst_dir
	echo -e "$name $version: installed.";$name -c
else
	a=$(md5sum "$_script"|sed "s:  .*$name.sh::")
	b=$(md5sum $inst_dir|sed "s:  $inst_dir::")
	if [[ "$a" != "$b" ]]; then
		printf %b "                 > $name $version available.\\r"
		read -n 1 -erp "update? Y/n: " update
		case $update in
			Y|y|'')
				sudo cp -u "$_script" $inst_dir;sudo chmod 777 $inst_dir
				echo -e "$name: updated to $version.";$name -c;exit 0;;
			n) echo "$name: not updated.";return;;
		esac
	else
		echo -e "$name: up-to-date -- $version."
	fi
fi
}

version="v6.50"
name="parse"
_script=parse.sh
directory=~/.parseHub
if [ ! -d $directory ]; then mkdir $directory;fi
if [ "$PWD" != "$directory" ]; then cd $directory; fi
arch=$(uname)
if [ "$arch" = Linux ]; then inst_dir=/usr/bin/$name
elif [ "$arch" = Darwin ]; then inst_dir=/usr/local/bin/$name
fi

if [ ! -d url_parser ]; then
	git clone https://github.com/looneytkp/url_parser.git 2> /dev/null
	cd url_parser
	run
else
	cd url_parser
	git pull -q
	run
fi
