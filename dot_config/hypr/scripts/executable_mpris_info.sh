#!/usr/bin/bash

CACHE_DIR="$HOME/.cache/hyprlock_media"
CACHE_ARTIST="${CACHE_DIR}/artist"
CACHE_TITLE="${CACHE_DIR}/title"
CACHE_LENGTH="${CACHE_DIR}/length"
CACHE_ALBUM_ART="${CACHE_DIR}/album_art.png"
SQUARE_SIZE=512
MAX_CACHE_FILES=10
mkdir -p "$CACHE_DIR"

NEED_REFRESH=false

get_metadata() {
	key=$1

	playerctl metadata --format "{{ $key }}" 2>/dev/null
}

resize_image() {
	input="$1"

	if command -v magick &> /dev/null; then
		magick "$input" -auto-orient -gravity center \
		  -thumbnail "${SQUARE_SIZE}x${SQUARE_SIZE}^" \
		  -extent "${SQUARE_SIZE}x${SQUARE_SIZE}" \
		  -quality 90 "${CACHE_ALBUM_ART}"
	else
		cp "$input" "${CACHE_ALBUM_ART}"
	fi
}

download_to_cache() {
	url="$1"
	filename="$(printf '%s' "$url" | sha256sum | awk '{print $1}').img"
	output="${CACHE_DIR}/$filename"

	if [[ ! -f "$output" ]]; then
		if [[ ! -s "$output" ]]; then
			curl -fsSL --max-time 5 "$url" -o "$output"
		fi
	fi

	if [[ -f "$output" ]]; then
		resize_image "$output"
	fi
}

get_media_title() {
	title=$(get_metadata "xesam:title")
	title="${title:0:15}"

	if [[ ! -f "$CACHE_TITLE" ]]; then
		NEED_REFRESH=true
	else
		cached_title=$(cat "$CACHE_TITLE")
		if [ "$cached_title" != "${title}" ]; then
			NEED_REFRESH=true
		fi
	fi

	if [[ "$NEED_REFRESH" == true ]]; then
		echo "${title}" > "$CACHE_TITLE"
	fi
}

get_media_artist() {
	artist=$(get_metadata "xesam:artist")
	artist="${artist:0:15}"

	if [[ ! -f "$CACHE_ARTIST" ]]; then
		NEED_REFRESH=true
	else
		cached_artist=$(cat "$CACHE_ARTIST")
		if [ "$cached_artist" != "${artist}" ]; then
			NEED_REFRESH=true
		fi
	fi

	if [[ "$NEED_REFRESH" == true ]]; then
		echo "${artist}" > "$CACHE_ARTIST"
	fi
}

get_media_length() {
	length=$(get_metadata "mpris:length")

	if [[ ! -z "$length" ]]; then
		# Convert length from microseconds to a more readable format (seconds)
		seconds=$((length / 1000000))
		length=$(printf "%02d:%02d\n" $((seconds / 60)) $((seconds % 60)))
	fi

	if [[ ! -f "$CACHE_LENGTH" ]]; then
		NEED_REFRESH=true
	else
		cached_length=$(cat "$CACHE_LENGTH")
		if [ "$cached_length" != "${length}" ]; then
			NEED_REFRESH=true
		fi
	fi

	if [[ "$NEED_REFRESH" == true ]]; then
		echo "${length}" > "$CACHE_LENGTH"
	fi

}

get_media_album_art() {
	url=$(get_metadata "mpris:artUrl")

	local_path=""
	echo "Album Art URL: $url"
	case "$url" in
	file://*)
		local_path="${url#file://}"
		local_path="$(printf '%b' "${local_path//%/\\x}")"
		filename="$(printf '%s' "$local_path" | sha256sum | awk '{print $1}').img"
		cp "$local_path" "$CACHE_DIR/$filename"
		resize_image "$CACHE_DIR/$filename"
		;;
	http://* | https://*)
		download_to_cache "$url"
		;;
	"")
		cp "$HOME/.config/hypr/scripts/music.png" "$CACHE_ALBUM_ART"
		;;
	*)
		return
	;;
	esac
}

get_status() {
	status=$(playerctl status 2>/dev/null)
	if [[ $status == "Playing" ]]; then
		echo ""
	elif [[ $status == "Paused" ]]; then
		echo ""
	elif [[ $status == "Stopped" ]]; then
		echo ""
	else
		echo ""
	fi
}

get_source_info() {
	trackid=$(get_metadata "mpris:trackid")
	if [[ "$trackid" == *"firefox"* ]]; then
		echo -e "Firefox 󰈹"
	elif [[ "$trackid" == *"spotify"* ]]; then
		echo -e "Spotify "
	elif [[ "$trackid" == *"chromium"* ]]; then
		echo -e "Chrome "
	else
		echo ""
	fi
}

status=$(get_status)

if [[ -z $status ]]; then
	# Clear cache if no media is playing
	echo "No Media Playing" > "$CACHE_TITLE"
	echo "No Artist" > "$CACHE_ARTIST"
	echo "󰎊" > "$CACHE_LENGTH"
	rm -f "$CACHE_ALBUM_ART"
else
	get_media_title
	get_media_artist
	get_media_length

	if [[ ! -f "$CACHE_ALBUM_ART" ]]; then
		NEED_REFRESH=true
	fi
	
	if [[ "$NEED_REFRESH" == true ]]; then
		get_media_album_art
	fi

	# clean up old cache files, keep only the most recent ones
	( ls -t "$CACHE_DIR"/*.img 2>/dev/null | tail -n +$((MAX_CACHE_FILES + 1)) | xargs -r rm -f ) &
fi

# Parse the argument
case "$1" in
--status)
	echo $status
	;;
--source)
	if [[ -z $status ]]; then
		echo "No Player"
	else
		get_source_info
	fi
	;;
--album)
	if [[ -z $status ]]; then
		echo "~/.config/hypr/scripts/music.png"
	else
		echo "$CACHE_ALBUM_ART"
	fi
	;;
*)
	echo "Invalid option: $1"
	echo "Usage: $0 --status | --source | --album"
	exit 1
	;;
esac
