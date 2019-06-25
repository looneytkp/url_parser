#!/usr/bin/env bash
set -ex

# omdbapi.com #
omdb_api_key=7759dbc7
#q=$(grep -E $format "$ct"|head -1|sed -e "s/.*\">//")
#r=$(echo $q|grep -ioE ".([0-9][0-9][0-9][0-9]|web-dl).*(avi|flv|wmv|mov|mp4|mkv)")
#omdb=$(echo $q|sed "s/$r.*//")
omdb_series_name=$(grep -E $format "$out"|head -1|sed -e "s/.*\">//" -e "s/[S-s][0-9][0-9].*//" -e 's/.[0-9][0-9].*//')
if grep -q "\." <<< "$omdb_series_name"; then
    omdb_series_name=$(grep "\." <<< "$omdb_series_name" | sed -e "s:\.:%20:g" -e "s:%20$::")
fi
if grep -q "\_" <<< "$omdb_series_name"; then
    omdb_series_name=$(grep "\_" <<< "$1" | sed -e "s:\_:%20:g" -e "s:%20$::")
fi
curl -s -i -H "Accept: application/json" -H "Content-Type: application/json" "http://www.omdbapi.com/?t=$omdb_series_name&type=Series&plot=short&apikey=$omdb_api_key" -o "$txt" -w curl #"$tmp_directory"/curl
if grep -q "200 OK" "$txt"; then
    grep '{' "$txt" | jq '.' | grep -E "(Title|Year|Genre|Plot|imdbRating|imdbID|Type)" | sed 's:",::' > "$json"
    imdb_id=$(grep "imdbID" "$json" | sed 's_.*: "__')

    # themoviedb.org #
#    tmdb_api_key=0dec8436bb1b7de2bbcb1920ac31111f
#    tmdb_poster_URL=https://image.tmdb.org/t/p/w500
#    curl -s -i -H "Accept: application/json" -H "Content-Type: application/json" -X GET "https://api.themoviedb.org/3/find/$imdb_id?api_key=$tmdb_api_key&external_source=imdb_id" -o "$txt" -w "$tmp_directory"/curl
#    if grep -q "200 OK" "$txt"; then
#        grep '{' "$txt" | jq '.' | grep poster_path | sed -e "s-: \"-: \"$tmdb_poster_URL-" -e 's:",::' >> "$json"
#    fi
fi
