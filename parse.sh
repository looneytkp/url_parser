#!/bin/bash
# by_looneytkp #
set -e
start=`date +%s`

_install(){	# function to install parse #
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
				# update parse when already installed #
				sudo -p ":: input password to update parse: " cp -u "$0" /usr/bin/parse
				echo -e ":: parse is updated."
				exit
			fi
		fi
	fi
	which xclip > /dev/null || stat=1 # check if xclip is installed #
	if [ $stat ]; then echo ":: install xclip." && exit; fi
}

sig_abort(){
	cleanup && echo -e "\\n:: aborted.\\n" && exit 0
}

cleanup(){	# clean up residues before and after execution #
	#if [ -e "$tmp_directory"/err ]; then echo -e "\\nlogs:"; cat -n "$tmp_directory"/err && echo; fi # print logs if found #
	rm -rf "$tmp_directory" "$PIO_directory" "$summary_directory" "$out" 2> /dev/null # remove directories #
}

connect(){	# checks for connection errors #
	wget -q --spider google.com && exitStatus=$?||exitStatus=4
	if [ $exitStatus == 0 ]; then
		if grep -q "404" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: 404 not found.\\n"
		elif grep -q "service not known" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: service unknown.\\n"
		elif grep -q "Connection refused" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: connection refused.\\n"
		elif grep -q "503" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: service temporarily unavailable.\\n"
		elif grep -q "timed out" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: connection timed out.\\n"
		fi
	else
		echo -e "\\n:: no internet connection.\\n"
	fi
	cleanup && exit
}

parsing(){	# parser #
	if [ "$#" != 0 ]; then
		# download html file #
		wget --timeout=10 --waitretry=0 --tries=2 --retry-connrefused -k "$positional_parameter" -o "$tmp_directory"/.wget -O "$ct" || connect	##

		# removes needed text, excluding junk #
		grep -iowE "<a href=$format" "$ct" | grep -vE '.*(amp|darr).*' | sed "s:.*<a href:<a href:" > "$ct2" && mv "$ct2" "$ct" || stat=$?	##
		if [ $stat ]; then echo -e "\\n:: error: $positional_parameter\\n"; cleanup && exit; fi

		# get trailers if available #
		# get trailer code goes here #

		# gets season tag of current url and create a text file for it #
		title=$(grep -io "s[0-9][0-9]" "$ct"|head -1|sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/' || grep -io "s[0-9]" "$ct"|head -1|sed -e "s/[S-s]/<h3>Season 0/" -e 's/$/<\/h3>/')
		tag=$(echo "$title"|grep -o "[0-9][0-9]" || echo movie)
		if [ ! -e "$summary_directory"/s"$tag" ]; then
			if [ $tag == movie ]; then
				touch "$summary_directory"/s"$tag"
			else
				echo -e "$title" > "$summary_directory"/s"$tag"
			fi
		fi	##

		# get info for omdb #
		if [ ! "$omdb" ]; then
			if [ $tag == movie ]; then
				q=$(grep -E $format "$ct"|head -1|sed -e "s/.*\">//")
				r=$(echo $q|grep -ioE ".([0-9][0-9][0-9][0-9]|web-dl).*(avi|flv|wmv|mov|mp4|mkv)")
				omdb=$(echo $q|sed "s/$r.*//")
				#year=$(grep -E $format "$ct"|head -1|grep -oE '(.)[0-9][0-9][0-9][0-9]'|sed 's/.//'|head -1)
			else
				omdb=$(grep -E $format "$ct"|head -1|sed -e "s/.*\">//" -e "s/[S-s][0-9][0-9].*//" -e 's/.[0-9][0-9][0-9][0-9].*//')
				#year=$(grep -E $format "$ct"|head -1|grep -oE '(.)[0-9][0-9][0-9][0-9]'|sed 's/.//'|head -1)
			fi
			#if [ $year == '' ]||[ $year == 1080 ]||[ $year == 2160 ]; then unset year; fi
		fi

		# loop orderly to parse pixel resolutions #
		if ! grep -qE "(480p|720p|1080p|2160p)" "$ct"; then
			grep -E "<a href=\"$format" "$ct" > "$PIO_directory"/noFormat && echo "s$tag noFOrmat" >> "$tmp_directory"/txt
			sort -n "$PIO_directory"/noFormat >> "$summary_directory/s$tag" 2> /dev/null || true
			rm "$ct"
			return
		fi

		if [ "$first_pixel" ]; then f=(480p)
		elif [ "$second_pixel" ]; then f=(720p)
		elif [ "$third_pixel" ]; then f=(1080p)
		elif [ "$fourth_pixel" ]; then f=(2160p)
		else f=(480p 720p 1080p 2160p)
		fi

		for f in "${f[@]}"; do
			grep -vE "$f.*(x264|x265)" "$ct" > "$tmp_directory"/ct3 && grep "$f" "$tmp_directory"/ct3 > "$PIO_directory"/main && echo "s$tag $f main" >> "$tmp_directory"/txt && rm "$tmp_directory"/ct3|| rm "$tmp_directory"/ct3
			# for x264 argument #
			if [ ! "$x5" ]; then
				grep "$f" "$ct" | grep "x264" > "$PIO_directory"/x264 && echo "S$tag $f x264" >> "$tmp_directory"/txt || if [ "$x4" ]; then echo -e "\\n:: error $positional_parameter\\n:: x264 not found.\\n"; cleanup; exit; else rm "$PIO_directory"/x264; fi
			fi	##
			# for x265 argument #
			if [ ! "$x4" ]; then
				grep "$f" "$ct" | grep "x265" > "$PIO_directory"/x265 && echo "s$tag $f x265" >> "$tmp_directory"/txt || if [ "$x5" ]; then echo -e "\\n:: error $positional_parameter\\n:: x265 not found.\\n"; cleanup; exit; else rm "$PIO_directory"/x265; fi
			fi	##

			# sort texts in numerical order #
			for files in "$PIO_directory"/*; do
				sort -n "$files" >> "$summary_directory/s$tag" 2> /dev/null || true
			done	##

		done
		rm "$ct"

	else

		# for 480p, 720p, 1080p & 2160p arguments #
		if [ "$first_pixel" ]||[ "$second_pixel" ]||[ "$third_pixel" ]||[ "$fourth_pixel" ]; then
			if [ "$first_pixel" ]; then
				if ! grep -qi "$first_pixel" "$summary_directory"/*; then
					echo -e ":: error: $f not found.\\n"; cleanup && exit
				fi
			elif [ "$second_pixel" ]; then
				if ! grep -qi "$second_pixel" "$summary_directory"/*; then
					echo -e ":: error: $f not found.\\n"; cleanup && exit
				fi
			elif [ "$third_pixel" ]; then
				if ! grep -qi "$third_pixel" "$summary_directory"/*; then
					echo -e ":: error: $f not found.\\n"; cleanup && exit
				fi
			elif [ "$fourth_pixel" ]; then
				if ! grep -qi "$fourth_pixel" "$summary_directory"/*; then
					echo -e ":: error: $f not found.\\n"; cleanup && exit
				fi
			fi
		fi	##

		touch $out

		# adds alignment & movie description #
		if [ ! "$no_alignment" ]; then
			echo -e "[vc_row][vc_column column_width_percent=\"100\" align_horizontal=\"align_center\" overlay_alpha=\"50\" gutter_size=\"3\" medium_width=\"0\" mobile_width=\"0\" shift_x=\"0\" shift_y=\"0\" shift_y_down=\"0\" z_index=\"0\" width=\"1/1\"][vc_column_text]" >> $out

			if [ $tag == movie ]; then
				curl -s -H "Accept: application/json" -H "Content-Type: application/json" "http://www.omdbapi.com/?t=$omdb&type=Movie&plot=short&apikey=7759dbc7" -o "$tmp_directory"/description
			else
				curl -s -H "Accept: application/json" -H "Content-Type: application/json" "http://www.omdbapi.com/?t=$omdb&type=Series&plot=short&apikey=7759dbc7" -o "$tmp_directory"/description
			fi
			if grep -qiE "(Movie not found!|error)" "$tmp_directory"/description; then
				echo -e "\\n>>>  paste movie description here  <<<" >> $out
			else
				desc=$(sed -e "s/.*Plot\":\"//" -e "s/\",\"Lan.*//" "$tmp_directory"/description)
				echo -e "\\n$desc" >> $out
			fi
		fi	##

		# finalize parsing by sorting resolutions, add titles  & copy to clipboard
		for file in "$summary_directory"/*; do
			title=$(grep -io "s[0-9][0-9]" "$file"|head -1|sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/' || grep -io "s[0-9]" "$ct"|head -1|sed -e "s/[S-s]/<h3>Season 0/" -e 's/$/<\/h3>/')
			tag=$(echo "$title"|grep -o "[0-9][0-9]" || echo movie)
			if [ ! "$no_title" ]; then grep -q "$title" $out || echo -e "\\n$title" >> $out; fi

			if ! grep -qE "(480p|720p|1080p|2160p)" "$file"; then
				if [ $tag == movie ]; then
					{ echo; cat $file; } >> $out
				else
					grep -qwoi "s$tag noFOrmat" "$tmp_directory"/txt && grep -v "$title" "$file" | grep -vE "(480p|720p|1080p|x264|x265)" >> $out
				fi

			else

				f=(480p 720p 1080p 2160p)
				for f in "${f[@]}"; do
					if [ ! "$x4" ]||[ ! "$x5" ]; then
						grep -qwoi "s$tag $f main" "$tmp_directory"/txt && echo -e "\\n$f\\n" >> "$out" && grep "$f" "$file" | grep -vE "(x264|x265)" >> $out
					fi
					grep -qwoi "s$tag $f x264" "$tmp_directory"/txt && echo -e "\\n$f x264\\n" >> "$out" && grep "$f.*x264" "$file" >> $out
					grep -qwoi "s$tag $f x265" "$tmp_directory"/txt && echo -e "\\n$f x265\\n" >> "$out" && grep -E "$f.*x265" "$file" >> $out
				done

			fi

		done

		if [ ! "$no_alignment" ]; then echo -e "\\n[/vc_column_text][/vc_column][/vc_row]" >> $out; fi
		xclip -sel clip < $out
		echo -e ":: copied to clipboard."; rm $out; return	##
	fi
}

trap sig_abort SIGINT
_install

# variables #
format='.*(avi|flv|wmv|mov|mp4|mkv).*</a>'	# format #
tmp_directory="$PWD/.temp"; PIO_directory="$PWD/.PIO"; summary_directory="$PWD/.finished"	# directories #
ct="$tmp_directory/xy"; ct2="$tmp_directory/yx"; out=.parsed	# files #

cleanup; params=$#

if [ $params == 0 ]; then echo ":: no url to parse."; cleanup; exit; fi	# exit when arguments is null #
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
	# ignores parse arguments if parsed #
	if [ "$positional_parameter" == -r ]||[ "$positional_parameter" == -a ]||[ "$positional_parameter" == -t ]||[ "$positional_parameter" == -480p ]||[ "$positional_parameter" == -720p ]||[ "$positional_parameter" == -1080p ]||[ "$positional_parameter" == -2160p ]||[ "$positional_parameter" == -x4 ]||[ "$positional_parameter" == -x5 ]; then
		if [ $params == 0 ]; then echo ":: no url to parse."; cleanup && exit; fi
		continue
	else
		printf %b ":: parsing $params URL(s): $percentage%\\r"
		# checks for redundant arguments #
		check_url=$(echo "$positional_parameter"|grep "http"||echo error)
		if [ "$check_url" == error ]; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: invalid URL.\\n"; cleanup && exit
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

parsing && cleanup
end=`date +%s`
runtime=$( echo "$end - $start" | bc -l )
echo -e ":: runtime: $runtime\s\\n"
exit 0
# end of script #
