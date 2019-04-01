#!/bin/bash
set -e

if [ ! -e /usr/bin/parse ]; then
	sudo cp -u parse.sh /usr/bin/parse
	echo -e "parse is installed."
	exit
elif [ $0 == parse.sh ]; then
	bin=$(md5sum /usr/bin/parse|sed "s/ .*//")
	script=$(md5sum $0|sed "s/ .*//")
	if [ $script != $bin ]; then
		sudo cp -u parse.sh /usr/bin/parse
		echo -e "parse is updated."
		exit
	fi
fi

format='.*(webrip|avi|flv|wmv|mov|mp4|mkv|3gp|webm|m4a|m4v|f4a|f4v|m4b|m4r|f4b).*</a>'
directory='.temp'
ct=.ct; ct2=.ct2; out=.out; out2=.out2
arch=$(uname)

cleanup(){
	if [ -e .out ]; then rm .out*; fi
	if [ -e .ct ]; then rm .ct*; fi
	if [ -e .ct2 ]; then rm .ct*; fi
	if [ -e .wget ]; then rm .wget; fi
	if [ -d "$directory" ]; then rm -rf "$directory"; fi
	if [ -e .logs ]; then echo -e "logs:" && cat -n .logs; rm .logs; fi
}
sig_abort(){
	cleanup && echo -e "\\naborted.\\n" && exit 0
}
connect(){
	wget -q --spider google.com && exitStatus=$?||exitStatus=4
	if [ $exitStatus == 0 ]; then
		if grep -q "404" .wget;then echo -e "\\n:: error: 404 not found.\\n"
		elif grep -q "Name or service not known" .wget;then
			echo -e "\\n:: service unknown: '$positional_parameter'\\n"
		fi
	else
		echo -e "\\n:: no internet connection.\\n"
	fi
	cleanup && exit
}
dl(){
	wget -k "$positional_parameter" -o .wget -O $ct||connect
	if ! grep -qE "$format" $ct; then echo -e ":: error: $positional_parameter\\n"; cleanup; exit; fi
	if grep -qiE '(&amp|&darr)' $ct; then
		grep -vE '.*(amp|darr).*' $ct > $ct2
		mv $ct2 $ct
	fi
	if grep -qioE "trailer" $ct; then
		{
			echo -e "\\nTrailer\\n"
			grep -iwE ".*trailer.*</a>" $ct|sed 's:.*<a:<a:';echo
		} >> $out
	fi
}
title(){
	if [ $no_title ]; then
		return
	else
		{	if grep -qioE "(s[0-9][0-9]|s[0-9])" $ct; then
				_a=$(grep -ioE "(s[0-9][0-9]|s[0-9])" $ct|head -1|sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/')
				echo -e "$_a"
			else
				movies=yes
		  	fi
		} >> $out
	fi
}
place_in_order(){
	if [ "$movies" ]; then return; fi
	c=1; d=1
	lines=$(wc -l<$out)
	if grep -q "Season" $out; then grep "Season" $out >> $ct2; lines=$((lines-1)); fi
	while true; do
		if [ $c -le $lines ]; then
			if [ $d -gt 9 ]; then e="(e$c|e0$c|-e$c|-$c)"
			else e="(e$c|e0$c|e00$c|-e0$c|-0$c)"
			fi
			grep -iwE ".*$e" $out >> $ct2||echo "$e does not exists." >> .logs
			c=$((c+1)); d=$((d+1))
		else
			if [ -e $ct2 ]; then mv $ct2 $out; else echo "place in order failed: $positional_parameter" >> .logs; fi
			break
		fi
	done
}
sort_(){
	#variable change to run final sort_
	if [ "$1" == final ]; then ct=$file; grep -o '.*Season.*' "$ct"|head -1 >> $out; fi
	#run if -x264 or -x265 arguments is passed
	if [ $x4 ]; then
		if ! grep -q "$x4" $ct; then
			echo -e "\\n:: null: $x4.\\n"; cleanup && exit
		fi
	elif [ $x5 ]; then
		if ! grep -q "$x5" $ct; then
			echo -e "\\n:: null: $x5.\\n"; cleanup && exit
		fi
	fi
	if ! grep -qE "(480p|720p|1080p)" $ct; then echo >> $out
		if [ "$1" == final ]; then
			grep -iowE "$format" $ct >> $out
		else
			grep -iowE "$format" $ct|sed 's:.*<a:<a:' >> $out
		fi
	else
		#get 480p, 720p & 1080p only
		if [ $first_pixel ]; then f=(480p); if ! grep -q "$first_pixel" $ct; then echo -e "\\n:: null: $first_pixel.\\n"; cleanup && exit; fi
		elif [ $second_pixel ]; then f=(720p); if ! grep -q "$second_pixel" $ct; then echo -e "\\n:: null: $second_pixel.\\n"; cleanup && exit; fi
		elif [ $third_pixel ]; then f=(1080p); if ! grep -q "$third_pixel" $ct; then echo -e "\\n:: null: $third_pixel.\\n"; cleanup && exit; fi
		else f=(480p 720p 1080p)
		fi
		touch $ct2
		for f in "${f[@]}"; do
			if [ "$1" == final ]; then
				if grep -qioE "$f" "$file"; then
					grep -E "$f" "$file" > $ct2
				fi
			else
				if grep -qioE "$f$format" $ct; then
					grep -iowE "<a href=.*$f$format" $ct > $ct2
				fi
			fi
			if [ $x4 ]||[ $x5 ]; then true
			else
			if grep -qE "(x264|x265)" $ct2; then
				flow(){
					size=$(wc -l<.ct3)
					if [ "$size" -gt 0 ]; then
						{	if [ "$final" == final ]; then echo -e "\\n$f\\n"; fi
							cat .ct3
						} >> $out
					fi
					rm .ct3
				}
				final=$1
				grep -vE "$f.*(x264|x265)" $ct2 >> .ct3 && flow || true
			else
				{	if [ "$1" == final ]; then echo -e "\\n$f\\n"; grep -E "$f" $ct2
					else
						size=$(wc -l<$ct2)
						if [ "$size" -ge 1 ]; then grep -owE "(.*$f$format)" $ct2; fi
					fi
					} >> $out
					continue
			fi
			fi
			#get x264 only
			if [ $x5 ]; then true
			else
				if grep -qioE "$f.*x264" $ct2; then
					{	if [ "$1" == final ]; then echo -e "\\n$f x264\\n"; fi
						grep -oiE ".*$f.*x264" $ct2
					} >> $out
				fi
			fi
			#get x265 only
			if [ $x4 ]; then true
			else
				if grep -qioE "$f.*x265" $ct2; then
					{	if [ "$1" == final ]; then echo -e "\\n$f x265\\n"; fi
						grep -oiE ".*$f.*x265" $ct2
					} >> $out
				fi
			fi
		done
	fi
	if [ "$1" == final ]; then return; fi
	if [ -e $ct2 ]; then rm .ct[2-3];fi
	place_in_order
}
header(){
	if [ $no_alignment ]; then
		return
	else
		if [ "$1" == top ]; then
			echo -e "[vc_row][vc_column column_width_percent=\"100\" align_horizontal=\"align_center\" overlay_alpha=\"50\" gutter_size=\"3\" medium_width=\"0\" mobile_width=\"0\" shift_x=\"0\" shift_y=\"0\" shift_y_down=\"0\" z_index=\"0\" width=\"1/1\"][vc_column_text]\\n\\n>>>  paste movie description here  <<<\\n" > $out
		else
			echo -e "\\n[/vc_column_text][/vc_column][/vc_row]" >> $out
		fi
	fi
}

parsing(){
set -x
	if [ ! -d $directory ]; then mkdir $directory; fi
	if [ $finalize == no ]; then
		lru=$(echo "$positional_parameter"|grep "http"||echo error)
		if [ "$lru" == error ]; then
			echo -e "\\n:: error: $positional_parameter\\n"
			cleanup && exit
		else
			dl; title; sort_
			if [ $movies ]; then cat $out >> $directory/mov; return; fi
			rm $ct
			tag=$(grep -o "Season [0-9][0-9]" $out|sed 's:Season ::'|head -1)
			if grep -oq "Season $tag" $out && grep -oqs "Season $tag" "$directory/s$tag"; then
				grep -v "Season $tag" $out >> $directory/s$tag; unset tag
			else
				cat $out >> $directory/s$tag
			fi
			truncate -s 0 $out
			return
		fi
	else
		header top
		for file in "$directory"/*;do sort_ final;done
		header
		xclip -sel clip < $out
		echo -e ":: copied to clipboard.\\n";rm $out;return
	fi

}
trap sig_abort SIGINT; cleanup
params=$#
flags=(r a t 480p 720p 1080p x264 x265)
for flag in "${flags[@]}"; do
	pattern=$(echo "$@"|grep -oE "\-$flag"||echo)
	if [ "$pattern" == '' ]; then continue
	elif [ "$pattern" == '-r' ]; then echo "resize"; params=$((params-1))
	elif [ "$pattern" == '-a' ]; then no_alignment=yes; params=$((params-1))
	elif [ "$pattern" == '-t' ]; then no_title=yes; params=$((params-1))
	elif [ "$pattern" == '-480p' ]; then first_pixel=480p; params=$((params-1))
	elif [ "$pattern" == '-720p' ]; then second_pixel=720p; params=$((params-1))
	elif [ "$pattern" == '-1080p' ]; then third_pixel=1080p; params=$((params-1))
	elif [ "$pattern" == '-x264' ]; then x4=x264; params=$((params-1))
	elif [ "$pattern" == '-x265' ]; then x5=x265; params=$((params-1))
	fi
done

if [ $params == 0 ]; then echo ":: no url to parse."; cleanup; exit; fi
percentage=0; counter=0; finalize=no
for positional_parameter; do
	if [ "$positional_parameter" == -r -o "$positional_parameter" == -a -o "$positional_parameter" == -t -o "$positional_parameter" == -480p -o "$positional_parameter" == -720p -o "$positional_parameter" == -1080p ]; then
		if [ $params == 0 ]; then echo ":: no url to parse."; exit; fi
		continue
	else
		printf %b "\\n:: parsing $params URL(s): $percentage%\\r"
		parsing "$positional_parameter"
		#algo to calculate progress in percentage
		divide=$(((100+(params-1))/params)); counter=$((counter+1)); modulo=$((100%divide))
		if [ $modulo == 0 ]; then percentage=$((divide*counter)); fi
		if [ $counter == $params ]; then
			percentage=$((percentage+modulo))
			echo ":: parsing $params URL(s): $percentage%";break
		fi
		if [ $modulo != 0 ]; then percentage=$((divide*counter)); fi
		#algo end
	fi
done
finalize=yes
parsing ""
cleanup && exit 0
