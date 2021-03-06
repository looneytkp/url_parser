#!/bin/bash
#looneytkp
version="v6.65"
set -e

format='.*(webrip|avi|flv|wmv|mov|mp4|mkv|3gp|webm|m4a|m4v|f4a|f4v|m4b|m4r|f4b).*</a>'
ct=.ct;ct2=.ct2;out=.out;out2=.out2;name="parse";directory=~/.parseHub;arch=$(uname)

cleanup(){
	if [ -e .out ]; then rm .out*; fi
	if [ -e .ct ]; then rm .ct*; fi
	if [ -e .ct2 ]; then rm .ct*; fi
	if [ -e .wget ]; then rm .wget; fi
	if [ -d "$_dir" ]; then rm -rf "$_dir"; fi
}

sig_abort(){
	cleanup && echo -e "\\naborted.\\n" && exit 0
}

abort(){
	cleanup
	if [ "$nd2" != '' ]; then echo > /dev/null
	else echo -e "aborted.\\n"
	fi
	exit 0		
}

title(){
	{ if grep -qioE "s[0-9][0-9]" $ct; then
			_a=$(grep -ioE "s[0-9][0-9]" $ct|head -1|
			sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/')
			echo -e "$_a"
	  fi
	} >> $out
}

update(){
if [ ! -d $directory ]; then return;fi
cd $directory;old_m=$(sed 's/-.*//' url_parser/.date);old_d=$(sed 's/.*-//' url_parser/.date)
new_m=$(date +%m);new_d=$(date +%d);month=$(((new_m-old_m)*30));day=$((new_d-old_d+month))
auto=$(grep "AUTOMATIC_UPDATE=" .conf|sed "s/AUTOMATIC_UPDATE=//")
if [ $day -ge 3 ]; then
	if [ "$auto" == NO ]; then
		read -n 1 -erp "check for updates ? Y/n : " c4u
		if [ "$c4u" == y ]; then $0 -u;fi;date +%m-%d > url_parser/.date
	else
		$0 -u;date +%m-%d > url_parser/.date
	fi
fi
cd - > /dev/null
}

PIO(){
	c=1; #touch $ct2
	while true; do
		if [ $c -gt 9 ]; then
			d="(e$c|e$c|-$c)"
		else
			d="(e$c|e0$c|-0$c)"
		fi
		if grep -qiwE ".*$d" $ct; then
			#if ! grep -qiwE ".*$d" $ct2; then
				grep -iwE ".*$d" $ct >> $ct2
				c=$((c+1))
			#else
			#	c=$((c+1))
			#fi
		else
			if [ -e $ct2 ]; then mv $ct2 $ct;fi
			break
		fi
	done
	parser
}

connect_(){
	echo "no internet connection."
	if [ -z "$(ls -A "$directory")" ]; then rm -rf "$directory";fi
	return 1
}

connect(){
	wget -q --spider google.com && exitStatus=$?||exitStatus=4
	if [ $exitStatus == 0 ]; then
		if [ "$nd2" != '' ];then
			if grep -q "404" .wget;then echo -e "\\n:: error 404: not found.\\n"
			elif grep -q "Name or service not known" .wget;then
				echo -e "\\n:: service unknown: '$url'\\n"
			fi
		else
			if grep -q "404" .wget; then echo "error 404: not found."
			elif grep -q "Name or service not known" .wget; then
				echo "service unknown: '$url'"
			fi
		fi
	else
		if [ "$nd2" != '' ]; then echo -e "\\n:: no internet connection.\\n"
		else echo "no internet connection."
		fi
	fi
	abort
}

dl(){
	#axel and aria2
	wget -k "$url" -o .wget -O $ct||connect
	if ! grep -qE "$format" $ct; then
		if [ "$nd2" != '' ];then echo -e ":: error: $url\\n" else echo -e "error: $url\\n";fi
		abort
	fi
	if grep -qiqE '(&amp|&darr)' $ct; then grep -vE '.*(amp|darr).*' $ct > $ct2;mv $ct2 $ct;fi
	if grep -qioE "trailer" $ct; then echo 'Trailer' >> $out
		{
			grep -iwE ".*trailer.*</a>" $ct|sed 's:.*<a:<a:';echo
		} >> $out
	fi
}

final(){
	echo >> $out && grep -o '.*Season.*' "$file"|head -1 >> $out
	if ! grep -qE "(480p|720p|1080p)" "$file"; then echo >> $out
		grep -iowE "$format" "$file" >> $out
	else
		f=(480p 720p 1080p)
		for f in "${f[@]}"; do
			#get 480p, 720p & 1080p only
			if grep -qioE "$f" "$file"; then grep -E "$f" "$file" > $ct2
				if grep -qE "(x264|x265)" $ct2; then
					perg(){ 
						size=$(wc -l<.ct3)
						if [ "$size" -ge 1 ]; then
							{
								echo -e "\\n$f\\n"; cat .ct3
							} >> $out
						fi
						rm .ct3
					}
					grep -vE "$f.*(x264|x265)" $ct2 >> .ct3 && perg || true
				else
					{
						echo -e "\\n$f\\n"; grep -E "$f" $ct2
					} >> $out
				fi
				#get x264 only
				if grep -qioE "$f.*x264" $ct2; then
					{
						echo -e "\\n$f x264\\n"; grep -oiE ".*$f.*x264" $ct2
					} >> $out
				fi
				#get x265 only
				if grep -qioE "$f.*x265" $ct2; then
					{
						echo -e "\\n$f x265\\n"; grep -oiE ".*$f.*x265" $ct2
					} >> $out 
				fi
			fi
		done
	fi
}

resize(){
	file=.resizer.txt
	if [ ! -d resized_images ]; then mkdir resized_images;fi
	if [ ! -d original_images ]; then mkdir original_images;fi
	if [[ -e $file ]]; then rm $file;fi
	find *.jpg *.png *.jpeg 2> /dev/null|grep -vE '(_c.jpg|_c.png|_c.jpeg)'|grep -n . > $file|| printf "\\r:: no images to convert\\n"
	cnt=1; mul=0; numberOfImgs=$(wc -l .resizer.txt|sed "s/ .resizer.txt//"); z=0
	while true;do
		if grep -q "$cnt:" $file; then
			printf %b ":: resizing $numberOfImgs images to 500x741: $mul%\\r"
			name=$(grep -w "$cnt:.*" $file|sed "s/"$cnt:"//")
			extension=$(grep "$name" $file|grep -oE '(.jpg|.png|.jpeg)')
			identify=$(identify -verbose "$name" 2>> .logs|grep Geometry|sed -e 's/.*: //' -e 's/+.*//' -e 's/x//')
			geometry=$(echo $identify|sed 's/x//')
			width=$(echo $identify|sed 's/x.*//')
			height=$(echo $identify|sed 's/.*x//')
			if [[ $extension == '.jpg' ]];then
				old='.jpg';new='_c.jpg'
			elif [[ $extension == '.png' ]]; then
				old='.png';new='_c.png'
			elif [[ $extension == '.jpeg' ]]; then
				old='.jpeg';new='_c.jpeg'
			fi
			new_name=$(grep -w "$cnt:.*" $file|sed "s/"$cnt:"//"|sed "s/$old/$new/")
			if [[ $geometry -lt 500741 ]]; then
				echo "$name is less than 500x741" >> .logs
			elif [[ $geometry -gt 500741 ]]; then
				convert "$name" -resize 500x741! -quality 55 resized_images/"$new_name" 2>> .logs
				mv "$name" original_images/		#~/.local/share/Trash/files
			elif [[ $geometry == 500741 ]]; then
				convert "$name" -quality 55 resized_images/"$new_name" 2>> .logs
				mv "$name" original_images/		#~/.local/share/Trash/files
			fi
			div=$(((100+(numberOfImgs-1))/numberOfImgs)); mod=$((100%div)); cnt=$((cnt+1)); z=$((z+1));
			if [ $mod == 0 ]; then mul=$((div*z)); fi
			if [ $z == $numberOfImgs ]; then
				mul=$((mul+mod))
				echo ":: resizing $numberOfImgs images to 500x741: $mul%"
				echo ":: saved to resized directory."
				break
			fi
			if [ $mod != 0 ]; then mul=$((div*z)); fi
		else
			break
		fi
	done
	rm $file
}

parser(){
	if ! grep -qE "(480p|720p|1080p)" $ct; then
		echo >> $out
		grep -iowE "$format" $ct|sed 's:.*<a:<a:' >> $out
	else
		#get 480p, 720p & 1080p only
		f=(480p 720p 1080p)
		for f in "${f[@]}"; do
			if grep -qioE "$f.*$format" $ct; then
				grep -owE ".*$f.*$format" $ct > $ct2
				if grep -qE "(x264|x265)" $ct2; then
					perg(){ 
						size=$(wc -l<.ct3)
						if [ "$size" -ge 1 ]; then
							{
								cat .ct3
							} >> $out
						fi
						rm .ct3
						}
					grep -vE "$f.*(x264|x265)" $ct2 >> .ct3 && perg || true
				else
					size=$(wc -l<$ct2)
					if [ "$size" -ge 1 ]; then
						{
							grep -owE "($f|$format)" $ct2
						} >> $out
					fi
				fi
				#get x264 only
				if grep -qioE "$f.*x264" $ct2; then
					{
						grep -oiE ".*$f.*x264" $ct2
					} >> $out
				fi
				#get x265 only
				if grep -qioE "$f.*x265" $ct2; then
					{
						grep -oiE ".*$f.*x265" $ct2
					} >> $out
				fi
			fi
		done
	fi
	if [ -e $ct2 ]; then rm .ct[2-3];fi
}

header(){
	if [ "$1" == top ]; then
		echo -e "[vc_row][vc_column column_width_percent=\"100\" align_horizontal=\"align_center\" overlay_alpha=\"50\" gutter_size=\"3\" medium_width=\"0\" mobile_width=\"0\" shift_x=\"0\" shift_y=\"0\" shift_y_down=\"0\" z_index=\"0\" width=\"1/1\"][vc_column_text]\\n\\n>>>  paste movie description here  <<<" > $out
	else
		echo -e "\\n[/vc_column_text][/vc_column][/vc_row]" >> $out
	fi
}

edit(){
	if [ "$1" == '' ]; then pixel=url;printf %b "          [paste any valid URL]\\r"
	else pixel=$1;printf %b "          [paste only $pixel URLs]\\r"
	fi
	read -erp "$pixel: " url
	if [ "$url" == "" ]; then
		abort
	else
		lru=$(echo "$url"|grep "http" || echo false)
		if [ "$lru" == false ]; then echo -e "error: $url.";b=$((b-1));edit;fi
	fi
	if [ ! -e $directory/.conf ]; then title='DEFAULT'
	else title=$(grep "AUTO_ADD_TITLE=" $directory/.conf|sed "s/AUTO_ADD_TITLE=//")
	fi
	if [ "$title" == DEFAULT ];then printf %b "                   [Y/n]\\r"
		read -n 1 -erp "add title?: " t
	elif [ "$title" == YES ]; then
		t=y
	else
		t=n
	fi
	if [ ! -e $directory/.conf ]; then header='NO'
	else header=$(grep "UNIVERSAL_HEADER=" $directory/.conf|sed "s/DEFAULT_HEADER=//")
	fi
	if [ "$1" == '' ]; then
		if [ "$header" == YES ]; then header top
			if [ "$t" == y ]||[ "$t" == '' ]; then dl;title;PIO;else dl;PIO;fi
			header
		else
			if [ "$t" == y ]||[ "$t" == '' ]; then dl;title;PIO;else dl;PIO;fi
		fi
	else
		dl
		if ! grep -q "$pixel" $ct; then echo -e "$pixel: no such text.\\n";abort
		else
			if [ "$header" == YES ]; then header top
				PIO; mv $out $out2
				if [ "$t" == y ]||[ "$t" == '' ]; then title; fi
				grep -iwE "$1" $out2 >> $out; rm $out2;header
			else
				PIO; mv $out $out2
				if [ "$t" == y ]||[ "$t" == '' ]; then title; fi
				grep -iwE "$1" $out2 >> $out; rm $out2
			fi
		fi
	fi
	if [ "$arch" == "Darwin" ]; then pbcopy < $out;else xclip -sel clip < $out;fi
	echo -e "copied to clipboard."
	rm $out $ct .wget
	if [ "$1" != -u ]||[ "$1" != -d ]; then update;fi;edit "$1"
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
			if [ "$arch" = "Darwin" ]; then rm $out && touch $out; else truncate -s 0 $out;fi
			status=0
		fi
	}
	_dir=".editmp";if [ ! -d $_dir ];then mkdir $_dir;fi;a=0;b=1;d=0;escape=$(echo "$escape")
	while true;do
		if [ $b -ge 10 ]; then d="";srt="$d$b"
		elif [ $b -le 10 ]; then if [ $b -eq 0 ]; then b=1; else d=0;srt="$d$b";fi
		fi
		if [ $a != 1 ]; then
			if [ "$escape" == no ]; then url=$position
			elif [ "$escape" == yes ]; then url=""
			fi
			case "$url" in
				"")
					if [ -z "$(ls -A $_dir)" ]; then
						abort
					else
						header top
						for file in "$_dir"/*;do final;done
						header
						if [ "$arch" == Darwin ];then
							pbcopy < $out;else xclip -sel clip < $out
						fi
						echo -e ":: copied to clipboard.\\n";rm $out;return
					fi;;
				*)
					lru=$(echo "$url"|grep "http"|| echo false)
					if [ "$lru" == false ]; then
						echo -e "\\n:: error: $url\\n"
							echo > $out;size=$(wc -l<$out);abort
					else
						dl;title;PIO;rm $ct
						compare
						return
					fi;;
			esac
		else
			break
		fi
	done
}

trap sig_abort SIGINT;cleanup
case $1 in
	""|480p|480P|720p|720P|1080p|1080P)	echo;edit "$1";;
	-p)
		touch $out
		if [ "$2" != '' ]; then
			escape=no;nd2="$2";n=$(($#-1));mul=0;z=0
			echo
			for position;do
				if [ "$position" == -p ]; then
					continue
				else
					printf %b ":: auto parsing $n URL(s): $mul%\\r"
					'sort' "$position"
					if [ "$status" == 1 ]; then
						if grep -qo "404" .wget; then fb="404 not found"
						elif grep -qo "521" .wget; then fb="origin down"
						fi
						echo -e ":: $fb: $url.\\n";abort
					fi
				fi
			div=$(((100+(n-1))/n)); z=$((z+1));
			mod=$((100%div))
			if [ $mod == 0 ]; then mul=$((div*z)); fi
			if [ $z == $n ]; then
				mul=$((mul+mod));echo ":: auto parsing $n URL(s): $mul%";break
			fi
			if [ $mod != 0 ]; then mul=$((div*z)); fi
			done
			escape=yes; printf %b ":: assembling...\\r";sleep 1
			'sort' "$n";if [ "$1" != -u ]||[ "$1" != -d ]; then update;fi;abort
		else
			echo -e ":: no links added.";cleanup
		fi;;
	-u)
		if [ ! -e "$directory" ];then echo -e ":: standalone script: updates disabled.";exit
		else
			echo "checking for updates...";
			cd "$directory"
			if [ -e url_parser ];then
				(cd url_parser
				git pull -q 2> /dev/null||connect_)
				bash url_parser/install_parse.sh
			else
				printf "error: reinstall $name."
			fi
		fi;;
	-r)	
		resize
		if [ -e .logs ]; then
			size=$(wc -l .logs|sed "s/ .logs//")
			if [ $size != 0 ]; then
				echo -e "\\nerrors:"
				cat .logs|grep -n .|sed 's/:/: /'
			fi
			rm .logs
		fi;;
	-e) 
		if [ ! -e "$directory" ];then echo -e ":: standalone script: configuration unavailable."
		else nano "$directory"/.conf;fi;;
	-d)
		if [ ! -e "$directory" ];then echo -e ":: standalone script: uninstall unavailable.";exit;fi
		if [ "$arch" = Linux ]; then inst_dir=/usr/bin/$name
		elif [ "$arch" = Darwin ]; then inst_dir=/usr/local/bin/$name
		fi
		if [ -e $inst_dir ]; then sudo rm -rf $inst_dir $directory;echo "$name: uninstalled."
		else echo "$name is not installed"
		fi;;
	-v) echo -e "$name $version.\\nThis is free software: you are free to change and redistribute it.\\nWritten by looneytkp. <https://github.com/looneytkp/url_parser>.";;
	-h)	
		if [ ! -e "$directory" ];then echo -e ":: standalone script: help info unavailable.";exit;fi
		if [ -d "$directory" ]; then cat "$directory"/.help;fi;;
	*)	echo -e "invalid flag: $1."
		if [ -d "$directory" ]; then cat "$directory"/.help;fi;;
esac
#end of script
