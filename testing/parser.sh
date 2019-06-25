#!/usr/bin/env bash
set -ex

connect(){	# checks for connection errors #
	wget -q --spider google.com && exitStatus=$?||exitStatus=4
	if [ $exitStatus == 0 ]; then
		if grep -q "404" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: 404 not found.\\n"
		elif grep -qi "service not known" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: service unknown.\\n"
		elif grep -qi "Connection refused" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: connection refused.\\n"
		elif grep -q "503" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: service temporarily unavailable.\\n"
		elif grep -qi "timed out" "$tmp_directory"/.wget; then
			echo -e "\\n:: error $counter: $positional_parameter\\n:: connection timed out.\\n"
		fi
	else
		echo -e "\\n:: no internet connection.\\n"
	fi
	cleanup && exit
}

if [ "$#" != 0 ]; then
  # download html file #
  # aria2c -q "$positional_parameter" -l aria2c -d "$tmp_directory" -o "xy"
  wget --timeout=10 --waitretry=0 --tries=2 --retry-connrefused "$positional_parameter" -o "$tmp_directory"/.wget -O - | grep -iowE "<a href=$format" | grep -vE '.*(amp|darr).*' | sed "s:.*<a href:<a href:" > "$ct" || connect
  # removes needed text, excluding junk #
  #grep -iowE "<a href=$format" "$ct" | grep -vE '.*(amp|darr).*' | sed "s:.*<a href:<a href:" > "$ct2" && mv "$ct2" "$ct" || stat=$?	##
  #if [ $stat ]; then echo -e "\\n:: error: $positional_parameter\\n"; cleanup && exit; fi

  # get trailers if available #
  # get trailer code goes here #

  # gets season tag of current url and create a text file for it #
  season=$(grep -io "s[0-9][0-9]" "$ct" | head -1 | sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/' || grep -io "s[0-9]" "$ct" | head -1 | sed -e "s/[S-s]/<h3>Season 0/" -e 's/$/<\/h3>/')
  tag=$(echo "$season" | grep -o "[0-9][0-9]")
  if [ ! -e "$summary_directory"/s"$tag" ]; then echo -e "$season" > "$summary_directory"/s"$tag"; fi	##

  # loop orderly to parse pixel resolutions #
  if ! grep -qE "(480p|720p|1080p|2160p)" "$ct"; then
    grep -E "<a href=\"$format" "$ct" > "$PIO_directory"/noFormat && echo "s$tag noFOrmat" >> "$tmp_directory"/txt
    sort -n "$PIO_directory"/noFormat >> "$summary_directory/s$tag" 2> /dev/null || true
    rm "$ct"

  else

    f=(480p 720p 1080p 2160p)
    for f in "${f[@]}"; do
      grep -vE "$f.*(x264|x265)" "$ct" > "$tmp_directory"/ct3 && grep "$f" "$tmp_directory"/ct3 > "$PIO_directory"/main && echo "s$tag $f main" >> "$tmp_directory"/txt && rm "$tmp_directory"/ct3 || rm "$tmp_directory"/ct3

      grep "$f" "$ct" | grep "x264" > "$PIO_directory"/x264 && echo "S$tag $f x264" >> "$tmp_directory"/txt ||  rm "$PIO_directory"/x264

      grep "$f" "$ct" | grep "x265" > "$PIO_directory"/x265 && echo "s$tag $f x265" >> "$tmp_directory"/txt || rm "$PIO_directory"/x265

      # sort texts in numerical order #
      for files in "$PIO_directory"/*; do
        sort -n "$files" >> "$summary_directory/s$tag" 2> /dev/null || true
      done	##

    done
  fi
  rm "$ct"

else

  touch $out

  # finalize parsing by sorting resolutions, add titles  & copy to clipboard
  for file in "$summary_directory"/*; do
    season=$(grep -io "s[0-9][0-9]" "$file"|head -1|sed -e "s/[S-s]/<h3>Season /" -e 's/$/<\/h3>/' || grep -io "s[0-9]" "$file"|head -1|sed -e "s/[S-s]/<h3>Season 0/" -e 's/$/<\/h3>/')
    tag=$(echo "$season"|grep -o "[0-9][0-9]")
    echo -e "\\n$season" >> $out

    if ! grep -qE "(480p|720p|1080p|2160p)" "$file"; then
        grep -qwoi "s$tag noFOrmat" "$tmp_directory"/txt && grep -v "$season" "$file" | grep -vE "(480p|720p|1080p|x264|x265)" >> $out

    else

      f=(480p 720p 1080p 2160p)
      for f in "${f[@]}"; do
        #if [ ! "$x4" ]||[ ! "$x5" ]; then
          grep -qwoi "s$tag $f main" "$tmp_directory"/txt && echo -e "\\n$f\\n" >> "$out" && grep "$f" "$file" | grep -vE "(x264|x265)" >> $out
        #fi
        grep -qwoi "s$tag $f x264" "$tmp_directory"/txt && echo -e "\\n$f x264\\n" >> "$out" && grep "$f.*x264" "$file" >> $out
        grep -qwoi "s$tag $f x265" "$tmp_directory"/txt && echo -e "\\n$f x265\\n" >> "$out" && grep -E "$f.*x265" "$file" >> $out
      done

    fi

  done

exit 2
  ./get_json_data.sh

  echo -e "[vc_row][vc_column column_width_percent=\"100\" align_horizontal=\"align_center\" overlay_alpha=\"50\" gutter_size=\"3\" medium_width=\"0\" mobile_width=\"0\" shift_x=\"0\" shift_y=\"0\" shift_y_down=\"0\" z_index=\"0\" width=\"1/1\"][vc_column_text]\\n" > $out2

  { grep Plot $json | sed 's-.*: "--'; } >> $out2
  cat $out >> $out2

  echo -e "\\n[/vc_column_text][/vc_column][/vc_row]" >> $out2
  xclip -sel clip < $out2
  echo -e ":: copied to clipboard."

fi
