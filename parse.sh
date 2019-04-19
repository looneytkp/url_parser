#!/bin/bash
# by_looneytkp #
set -e
# function to install parse #
install(){
which parse > /dev/null || stat=1
if [ $stat ]; then
	sudo cp -u parse.sh /usr/bin/parse	# install parse if not installed #
	echo -e ":: parse is installed."
	exit
else
	if [ "$0" != /usr/bin/parse ]; then
		bin=$(md5sum /usr/bin/parse | sed 's: .*::')
		script=$(md5sum "$0" | sed 's: .*::')
		if [ "$bin" != "$script" ]; then
			sudo -p ":: input password to update parse: " cp -u "$0" /usr/bin/parse	# update parse whe already installed #
			echo -e ":: parse is updated."
			exit
		fi
	fi
fi
which xclip > /dev/null || stat=1 # check if xclip is installed #
if [ $stat ]; then echo ":: install xclip." && exit; fi
}
install
# variables #
format='.*(webrip|avi|flv|wmv|mov|mp4|mkv|3gp|webm|m4a|m4v|f4a|f4v|m4b|m4r|f4b).*</a>' # format #
tmp_directory="$PWD/.temp"; PIO_directory="$PWD/.PIO"; summary_directory="$PWD/.finished" # directories #
ct="$tmp_directory/xy"; ct2="$tmp_directory/yx"; out=.parsed # files #
sig_abort(){
	cleanup && echo -e "\\naborted.\\n" && exit 0
}
cleanup(){
	# clean up residues before and after execution #
	if [ -e "$tmp_directory"/err ]; then echo -e "\\nlogs:"; cat -n "$tmp_directory"/err && echo; fi # print logs if found #
	rm -rf "$tmp_directory" "$PIO_directory" "$summary_directory" 2> /dev/null # remove directories #
}
connect(){
	#wget -q --spider google.com && exitStatus=$?||exitStatus=4
	#if [ $exitStatus == 0 ]; then
	if grep -q "404" "$tmp_directory"/.wget; then
		echo -e "\\n:: error $counter: $positional_parameter\\n:: 404 not found.\\n"
	elif grep -q "Name or service not known" "tmp_directory"/.wget; then
		echo -e "\\n:: error $counter: $positional_parameter\\n:: service unknown: '$url'\\n"
	else
		echo -e "\\n:: no internet connection.\\n"
	fi
	cleanup && exit
}
parsing(){
	if [ "$#" != 0 ]; then
		# download html file #
		wget -k "$positional_parameter" -o "$tmp_directory"/.wget -O "$ct" || connect	##
		if [ ! $omdb ]; then omdb=$(grep -E $format "$ct"|head -1|sed -e "s/.*\">//" -e "s/[S-s][0-9][0-9].*//"); fi
		# removes needed text, excluding junk #
		grep -iowE "<a href=$format" "$ct" | grep -vE '.*(amp|darr).*' > "$ct2" && mv "$ct2" "$ct" || stat=$?	##
		if [ $stat ]; then echo -e ":: error: $positional_parameter\\n"; cleanup && exit; fi
		# get trailers if available #
		# get trailer code goes here #
		# gets season tag of current url and create a text file for it #
		title=$(grep -ioE "(s[0-9][0-9]|s[0-9])" "$ct"|head -1|sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/' || echo ":: no tag: $positional_parameter" >> "$tmp_directory"/err)
		tag=$(echo "$title"|grep -o "[0-9][0-9]")
		if [ ! -e "$summary_directory"/s"$tag" ]; then echo -e "$title" > "$summary_directory"/s"$tag"; fi	##
		# loop orderly to parse pixel resolutions #
		if [ "$first_pixel" ]; then f=(480p)
		elif [ "$second_pixel" ]; then f=(720p)
		elif [ "$third_pixel" ]; then f=(1080p)
		elif [ "$fourth_pixel" ]; then f=(2160p)
		else f=(480p 720p 1080p 2160p)
		fi
		for f in "${f[@]}"; do
			grep -vE "$f.*(x264|x265)" "$ct" > "$tmp_directory"/ct3 && grep "$f" "$tmp_directory"/ct3 > "$PIO_directory"/main && echo "s$tag $f main" >> "$tmp_directory"/txt && rm "$tmp_directory"/ct3 || if [ "$first_pixel" ]||[ "$second_pixel" ]||[ "$third_pixel" ]||[ "$fourth_pixel" ]; then echo -e "\\n:: error: $f not found.\\n"; cleanup && exit; else rm "$tmp_directory"/ct3; fi
			if [ ! "$x5" ]; then
				grep "$f" "$ct" | grep "x264" > "$PIO_directory"/x264 && echo "S$tag $f x264" >> "$tmp_directory"/txt || if [ "$x4" ]; then echo -e "\\n:: error: x264 not found.\\n"; cleanup; exit; else rm "$PIO_directory"/x264; fi
			fi
			if [ ! "$x4" ]; then
				grep "$f" "$ct" | grep "x265" > "$PIO_directory"/x265 && echo "s$tag $f x265" >> "$tmp_directory"/txt || if [ "$x5" ]; then echo -e "\\n:: error: x265 not found.\\n"; cleanup; exit; else rm "$PIO_directory"/x265; fi
			fi	##
			# sort texts in numerical order #
			for files in "$PIO_directory"/*; do
				sort -n "$files" >> "$summary_directory/s$tag" 2> /dev/null || true
			done	##
		done
		rm "$ct"
	else
		touch $out
		# adds alignment & movie description #
		if [ ! "$no_alignment" ]; then
			echo -e "[vc_row][vc_column column_width_percent=\"100\" align_horizontal=\"align_center\" overlay_alpha=\"50\" gutter_size=\"3\" medium_width=\"0\" mobile_width=\"0\" shift_x=\"0\" shift_y=\"0\" shift_y_down=\"0\" z_index=\"0\" width=\"1/1\"][vc_column_text]" >> $out
			curl -s -H "Accept: application/json" -H "Content-Type: application/json" "http://www.omdbapi.com/?t=$omdb&apikey=7759dbc7" -o "$tmp_directory"/description
			if grep -q "Movie not found!" "$tmp_directory"/description; then
				echo -e "\\n>>>  paste movie description here  <<<" >> $out
			else
				desc=$(sed -e "s/.*Plot\":\"//" -e "s/\",\"Lan.*//" "$tmp_directory"/description)
				echo -e "\\n$desc" >> $out
			fi
		fi	##
		# finalize parsing by sorting resolutions, add titles  & copy to clipboard
		for file in "$summary_directory"/*; do
			title=$(grep -ioE "(s[0-9][0-9]|s[0-9])" "$file"|head -1|sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/')
			tag=$(echo "$title"|grep -o "[0-9][0-9]")
			if [ ! "$no_title" ]; then grep -q "$title" $out || echo -e "\\n$title" >> $out; fi
			f=(480p 720p 1080p 2160p)
			for f in "${f[@]}"; do
				if [ ! "$x4" ]||[ ! "$x5" ]; then
					grep -qwoi "s$tag $f main" "$tmp_directory"/txt && echo -e "\\n$f\\n" >> "$out" && grep "$f" "$file" | grep -vE "(x264|x265)" >> $out
				fi
				grep -qwoi "s$tag $f x264" "$tmp_directory"/txt && echo -e "\\n$f x264\\n" >> "$out" && grep "$f.*x264" "$file" >> $out
				grep -qwoi "s$tag $f x265" "$tmp_directory"/txt && echo -e "\\n$f x265\\n" >> "$out" && grep -E "$f.*x265" "$file" >> $out
			done
		done
		if [ ! "$no_alignment" ]; then echo -e "\\n[/vc_column_text][/vc_column][/vc_row]" >> $out; fi
		xclip -sel clip < $out
		echo -e ":: copied to clipboard.\\n"; rm $out; return	##
	fi
}
trap sig_abort SIGINT; cleanup
params=$#
if [ $params == 0 ]; then echo ":: no url to parse."; cleanup; exit; fi # exit when arguments is null #
mkdir "$tmp_directory" "$PIO_directory" "$summary_directory"
arguments=(r a t 480p 720p 1080p 2160p x4 x5)
for argument in "${arguments[@]}"; do
	pattern=$(echo "$@"|grep -oE "\-$argument"||echo)
	if [ "$pattern" == '' ]; then continue
	elif [ "$pattern" == '-r' ]; then echo "resize"; params=$((params-1))
	elif [ "$pattern" == '-a' ]; then no_alignment=yes; params=$((params-1))
	elif [ "$pattern" == '-t' ]; then no_title=yes; params=$((params-1))
	elif [ "$pattern" == '-480p' ]; then first_pixel=480p; params=$((params-1))
	elif [ "$pattern" == '-720p' ]; then second_pixel=720p; params=$((params-1))
	elif [ "$pattern" == '-1080p' ]; then third_pixel=1080p; params=$((params-1))
	elif [ "$pattern" == '-2160p' ]; then fourth_pixel=2160p; params=$((params-1))
	elif [ "$pattern" == '-x4' ]; then x4=x264; params=$((params-1))
	elif [ "$pattern" == '-x5' ]; then x5=x265; params=$((params-1))
	fi
done
echo; percentage=0; counter=1
for positional_parameter; do
	if [ "$positional_parameter" == -r ]||[ "$positional_parameter" == -a ]||[ "$positional_parameter" == -t ]||[ "$positional_parameter" == -480p ]||[ "$positional_parameter" == -720p ]||[ "$positional_parameter" == -1080p ]||[ "$positional_parameter" == -2160p ]||[ "$positional_parameter" == -x4 ]||[ "$positional_parameter" == -x5 ]; then
		if [ $params == 0 ]; then echo ":: no url to parse."; cleanup && exit; fi
		continue
	else
		printf %b ":: parsing $params URL(s): $percentage%\\r"
		# checks for redundant arguments that aren't urls #
		check_url=$(echo "$positional_parameter"|grep "http"||echo error)
		if [ "$check_url" == error ]; then
			echo -e "\\n:: error $counter: $positional_parameter\\n"; cleanup && exit
		fi	##
		parsing "$positional_parameter"
		# simple algo to calculate progress in percentage #
		divide=$(printf %.0f "$(echo "100/$params" | bc -l)")
		percentage=$(printf %.0f "$(echo "$divide*$counter" | bc -l)")
		if [ $counter == $params ]; then
			subtract=$(printf %.0f "$(echo "100-$percentage" | bc -l)")
			percentage=$(printf %.0f "$(echo "$percentage+$subtract" | bc -l)")
			echo ":: parsing $params URL(s): $percentage%"
			break
		fi
		counter=$((counter+1))	##
	fi
done
parsing && cleanup && exit 0
# end of script #
