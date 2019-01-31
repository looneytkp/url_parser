#!/bin/bash
#looneytkp
version="v6.55"
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
		esac
	fi
fi
format='.*(webrip|avi|flv|wmv|mov|mp4|mkv|3gp|webm|m4a|m4v|f4a|f4v|m4b|m4r|f4b).*</a>'
ct=.ct
ct2=.ct2
out=.out
out2=.out2
name="parse"
directory=~/.parseHub

cleanup(){
	if [ -e .out ]; then rm .out*; fi
	if [ -e .ct ]; then rm .ct*; fi
	if [ -e .ct2 ]; then rm .ct*; fi
	if [ -e .wget ]; then rm .wget; fi
	if [ -d "$_dir" ]; then rm -rf "$_dir"; fi
}

sig_abort(){
	cleanup
	echo -e "\\naborted.\\n"
	exit 0
}

abort(){
	cleanup
	if [ "$nd2" != '' ]; then
		echo > /dev/null
	else
		echo -e "aborted.\\n"
	fi
	exit 0		
}

header(){
	{
		if grep -qioE "s[0-9][0-9]" $ct; then
			_a=$(grep -ioE "s[0-9][0-9]" $ct|head -1|
			sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/')
			echo "$_a"
		fi
	} >> $out
}

update(){
cd $directory
old_m=$(sed 's/-.*//' .date)
old_d=$(sed 's/.*-//' .date)
new_m=$(date +%m)
new_d=$(date +%d)
month=$(((new_m-old_m)*30))
day=$((new_d-old_d+month))
if [ $day -ge 3 ]; then
	read -n 1 -erp "check for updates ? Y/n : " c4u
	if [ $c4u == y ]; then $0 -u;fi
fi
}

PIO(){
	c=1
	while true; do
		if [ $c -gt 9 ]; then d="(e$c|e$c)";else d="(e$c|e0$c)";fi
		if grep -qiwE ".*$d" $ct; then
			grep -iwE ".*$d" $ct >> $ct2
		else
			if [ -e $ct2 ]; then mv $ct2 $ct;fi;break
		fi
		c=$((c+1))
	done
	parser
}

connect(){
	wget -q --spider google.com && exitStatus=$?||exitStatus=4
	if [ $exitStatus == 0 ]; then
		if [ "$nd2" != '' ];then
			if grep -q "404" .wget;then echo ":: error 404: not found."
			elif grep -q "Name orservice not known" .wget; then
				echo ":: service unknown: '$url'"
			fi
		else
			if grep -q "404" .wget; then echo "error 404: not found."
			elif grep -q "Name or service not known" .wget; then
				echo "service unknown: '$url'"
			fi
		fi
	else
		if [ "$nd2" != '' ]; then echo ":: no internet connection."
		else echo "no internet connection."
		fi
	fi
	abort
}

dl(){
	wget -k "$url" -o .wget -O $ct||connect
	if ! grep -qE "$format" $ct; then
		if [ "$nd2" != '' ]; then
			echo -e ":: error: $url\\n"
		else
			echo -e "error: $url\\n"
		fi
		abort
	fi
	if grep -iqE '(&amp|&darr)' $ct; then
		grep -vE '.*(amp|darr).*' $ct > $ct2;mv $ct2 $ct
	fi
	if grep -qioE "trailer" $ct; then
		echo 'Trailer' >> $out
		grep -iwE ".*trailer.*</a>" $ct|sed 's:.*<a:<a:';echo >> $out
	fi
}

final(){
	echo >> $out && grep -o '.*Season.*' "$file"|head -1 >> $out
	f=(480p 720p 1080p)
	for f in "${f[@]}"; do
		if grep -qioE "$f" "$file"; then
			grep -E "$f" "$file" > $ct2
			if grep -qE "(x264|x265)" $ct2; then
				perg(){ 
					size=$(wc -l<.ct3)
					if [ "$size" -ge 1 ]; then echo >> $out;cat .ct3 >> $out;fi;rm .ct3
				}
				grep -vE "$f.*(x264|x265)" $ct2 >> .ct3 && perg || true
			else
				echo >> $out;grep -E "$f" $ct2 >> $out
			fi
			if grep -qioE "$f.*x264" $ct2; then
				echo >> $out;grep -oiE ".*$f.*x264" $ct2 >> $out
			fi
			if grep -qioE "$f.*x265" $ct2; then
				echo >> $out;grep -oiE ".*$f.*x265" $ct2 >> $out
			fi
		fi
	done
}

parser(){
	if ! grep -qE "(480p|720p|1080p)" $ct; then
		echo >> $out
		grep -iowE "$format" $ct|sed 's:.*<a:<a:' >> $out
	else
		f=(480p 720p 1080p)
		for f in "${f[@]}"; do
			if grep -qioE "$f.*$format" $ct; then
				grep -owE ".*$f.*$format" $ct > $ct2
				if grep -qE "(x264|x265)" $ct2; then
					perg(){ 
						size=$(wc -l<.ct3)
						if [ "$size" -ge 1 ]; then echo -e "\\n$f" >> $out;cat .ct3 >> $out;fi
						rm .ct3
						}
					grep -vE "$f.*(x264|x265)" $ct2 >> .ct3 && perg || true
				else
					size=$(wc -l<$ct2)
					if [ "$size" -ge 1 ]; then
						echo -e "\\n$f" >> $out;grep -owE "($f|$format)" $ct2 >> $out
					fi
				fi
				#get x264 only
				if grep -qioE "$f.*x264" $ct2; then
					echo -e "\\n$f x264" >> $out;grep -oiE ".*$f.*x264" $ct2 >> $out
				fi
				#get x265 only
				if grep -qioE "$f.*x265" $ct2; then
					echo -e "\\n$f x265" >> $out;grep -oiE ".*$f.*x265" $ct2 >> $out
				fi
			fi
		done
	fi
	if [ -e $ct2 ]; then rm .ct[2-3];fi
}

edit(){
	if [ "$1" == '' ]; then
		pixel=url
		printf %b "          [paste any valid URL]\\r"
	else
		pixel=$1;printf %b "          [paste only $pixel URLs]\\r"
	fi
	read -erp "$pixel: " url
	if [ "$url" == "" ]; then
		abort
	else
		lru=$(echo "$url"|grep "http" || echo false)
		if [ "$lru" == false ]; then echo -e "invalid: $url.";b=$((b-1));edit;fi
	fi
	printf %b "                   [Y/n]\\r"
	read -n 1 -erp "add header?: " h
	if [ "$1" == '' ]; then
		if [ "$h" == y ]||[ "$h" == '' ]; then dl;header;PIO;else dl;PIO;fi
	else
		dl
		if ! grep -q "$pixel" $ct; then
			echo -e "$pixel: no such text.\\n"; abort
		else
			PIO; mv $out $out2
			if [ "$h" == y ]||[ "$h" == '' ]; then header; fi
			grep -iwE "$1" $out2 >> $out; rm $out2
		fi
	fi
	xclip -sel clip < $out
	echo -e "copied to clipboard."
	rm $out $ct .wget
	edit "$1"
}

sort(){
	compare(){
		size=$(wc -l<$out)
		if [ "$size" -le 1 ]; then
			status=1
		else
			cmpr=$(grep -iwoE "s$srt" $out|head -1|sed 's:[S-s]::')
			cmpr=$(grep -o "Season [0-9][0-9]" $out|sed 's:Season ::'|head -1)
			if grep -oq "Season $cmpr" $out && grep -oqs "Season $cmpr" "$_dir/s$cmpr";then
				sed -i "/Season $cmpr/d" $out
			else
				true
			fi
			cat $out >> "$_dir/s$cmpr";unset cmpr
			if [ "$arch" = Darwin ]; then rm $out && touch $out; else truncate -s 0 $out;fi
			status=0
		fi
	}
	_dir=.editmp
	if [ ! -d $_dir ]; then mkdir $_dir;fi
	a=0;b=1;d=0
	escape=$(echo "$escape")
	while true;do
		if [ $b -ge 10 ]; then d="";srt="$d$b"
		elif [ $b -le 10 ]; then if [ $b -eq 0 ]; then b=1; else d=0;srt="$d$b"; fi
		fi
		if [ $a != 1 ]; then
			if [ "$escape" == no ]; then
				url=$position
			elif [ "$escape" == yes ]; then
				url=""
			fi
			case "$url" in
				"")
					if [ -z "$(ls -A $_dir)" ]; then
						abort
					else
						echo -e "[vc_row][vc_column column_width_percent=\"100\" align_horizontal=\"align_center\" overlay_alpha=\"50\" gutter_size=\"3\" medium_width=\"0\" mobile_width=\"0\" shift_x=\"0\" shift_y=\"0\" shift_y_down=\"0\" z_index=\"0\" width=\"1/1\"][vc_column_text]\\n" > $out
						echo -e ">>>  paste movie description here  <<<" >> $out
						for file in "$_dir"/*;do final; done
						echo -e "\\n[/vc_column_text][/vc_column][/vc_row]" >> $out
						xclip -sel clip < $out
						if [ "$escape" == yes ]; then echo -e ":: copied to clipboard.\\n"
							rm $out
							return
						fi
					fi;;
				*)
						lru=$(echo "$url"|grep "http"|| echo false)
						if [ "$lru" == false ]; then
								echo ":: error: $url not a URL."
								echo > $out;size=$(wc -l<$out);abort
						else
							dl;header;PIO;rm $ct
							compare
							return
						fi
					;;
			esac
		else
			break
		fi
	done
	'sort'
}
trap sig_abort SIGINT
arch=$(uname)
cleanup; update
case $1 in
	""|480p|480P|720p|720P|1080p|1080P)	echo;edit "$1";;
	-p)	
		if [ "$2" != '' ]; then
			escape=no;nd2="$2";n=$#;n=$((n-1));n1=$n;mul=0;z=0
			echo
			for position;do
				if [ "$position" == -p ]; then
					continue
				else
					printf %b ":: auto parsing $n URL(s): $mul%\\r"
					'sort' "$position"
					if [ "$status" == 1 ]; then
						if grep -qo "404" .wget; then
							fb="404 not found"
						elif grep -qo "521" .wget; then
							fb="origin down"
						fi
						echo -e ":: $fb: $url.\\n"
						abort
					fi
				fi
			div=$((100/n1));mod=$((100%div));z=$((z+1));mul=$((div*z))
			if [ $z == $n1 ]; then 
				mul=$((mul+mod));echo ":: auto parsing $n URL(s): $mul%"
				break
			fi				
			done
			escape=yes; printf %b ":: assembling...\\r";sleep 1
			'sort' "$n";abort
		else
			echo -e ":: no links added."
		fi;;
	-u)
		echo "checking for updates..."
		cd "$directory"
		if [ -e url_parser ]; then
			bash url_parser/install_parse.sh
		else
			git clone https://github.com/looneytkp/url_parser.git 2> /dev/null
			bash url_parser/install_parse.sh
		fi;;
	-d)
		if [ "$arch" = Linux ]; then inst_dir=/usr/bin/$name
		elif [ "$arch" = Darwin ]; then inst_dir=/usr/local/bin/$name
		fi
		if [ -e $inst_dir ]; then sudo rm -rf $inst_dir $directory
			echo "$name: uninstalled."
		else
			echo "$name is not installed"
		fi;;
	-v) echo -e "version: $version.\\nby looneytkp.";;
	-c)	echo -e "\\nchangelog:\\n  - updated to $version.\\n  - added '-c' flag to display changelog.\\n  - changed '-s' flag to '-p'.\\n  - fixed problem with parsing header.\\n  - track auto parsing progress.\\n  - fixed progress errors.\\n  - updated strings in help.\\n  - display help when when flag is invalid.\\n  - display changelog after update & install.\\n";;
	-h)	echo -e "\\na simple URL parser.\\nusage: $name [...flag]\\nflags:\\n   480p   -   parse 480p URLs only.\\n   720p   -   parse 720p URLs only.\\n   1080p  -   parse 1080p URLs only.\\n     -p   -   automatic multi-URL parser.\\n     -i   -   install $name.\\n     -  check for updates.\\n     -d   -   uninstall $name.\\n     -c   -   display changelog.\\n     -v   -   display version.\\n     -h   -   display help.\\n";;
	*)	echo -e "unknown flag: $1.";bash "$0" -h;;
esac
