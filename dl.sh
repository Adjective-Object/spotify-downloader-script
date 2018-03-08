#!/usr/bin/env zsh

set -e
# set -x

if [ "$#" -lt 1 ]; then
    echo "usage: $0 <album-list.txt>"
    exit 1
fi

ALBUM_LIST_FILE=$(basename "$1")
UNIQUE_ID=${ALBUM_LIST_FILE%.*}
ALBUM_FOLDER="dl/album-lists-$UNIQUE_ID"
MUSIC_FOLDER="dl/music-$UNIQUE_ID"
ADB_DESTDIR="/storage/3862-3131/Music"
SPOTDL='python3 ~/Desktop/spotify-downloader/spotdl.py'

echo $'\e[34m'"downloading from album list file"$'\e[0m' $ALBUM_LIST_FILE

# Remove line comments from album list
ALBUM_LIST_TEXT=$(cat $ALBUM_LIST_FILE | sed 's/#.*$//g')

LIST_FILES=()
LIST_URLS=()
echo $'\e[34m'"downloading lists to"$'\e[0m' $ALBUM_FOLDER
mkdir -p $ALBUM_FOLDER
for album_url in $(echo $ALBUM_LIST_TEXT); do
  echo -n $'\e[34m'"listing album\e[0m" $album_url $'\e[34m'.. $'\e[0m'
  CREATED_LIST_FILE=$(eval "$SPOTDL -b '$album_url'" 2>&1 | grep -o '[^ ]*\.txt')
  mv $CREATED_LIST_FILE $ALBUM_FOLDER
  CREATED_LIST_FILE="$ALBUM_FOLDER/$CREATED_LIST_FILE"
  echo $'\e[34m'"created at"$'\e[0m' "$CREATED_LIST_FILE"
  LIST_FILES+=("$CREATED_LIST_FILE")
  LIST_URLS+=("$album_url")
done

echo $'\e[34m'"Downloading songs to $MUSIC_FOLDER"$'\e[0m'
for ((i=1;i<=${#LIST_FILES[@]};++i)); do
  album_list="${LIST_FILES[i]}"
  album_url="${LIST_URLS[i]}"
  ALBUM_SONG_FOLDER=$MUSIC_FOLDER/$(basename ${album_list%.txt})
  echo $'\e[34m'"downloading songs from list"$'\e[0m' $album_list $'\e[34m'"to"$'\e[0m' $ALBUM_SONG_FOLDER
  eval "$SPOTDL -l '$album_list' -f '$ALBUM_SONG_FOLDER' --overwrite=skip"
  # when the download is complete, remove the current song from the album list file
  TEXT=`cat $ALBUM_LIST_FILE | sed "s@$album_url@# $album_url@"`;
  echo $TEXT > "$ALBUM_LIST_FILE";
done

# Build a playlist file
PLAYLIST="$MUSIC_FOLDER/$UNIQUE_ID.m3u"
echo $'\e[34m'"Building playlist at"$'\e[0m' $PLAYLIST $'\e[34m'"..."$'\e[0m'
echo -n "" > $PLAYLIST
ALBUM_FOLDERS=$(find $MUSIC_FOLDER | grep '\.mp3$' | xargs dirname | uniq)
TEMP_ALBUM_LIST=`mktemp`

echo "$ALBUM_FOLDERS" | while IFS= read -r album_folder; do
	echo $'\e[34m'"Adding"$'\e[0m' $album_folder $'\e[34m'"to playlist"$'\e[0m'
	echo "" > $TEMP_ALBUM_LIST;
	for track_file in $album_folder/*; do
	 	TRACK_NUMBER=$(ffprobe $track_file 2>&1 | grep track | grep -v TMED | grep -o '[^ ]*/' | sed 's$/$$g');
	 	echo "$TRACK_NUMBER $track_file" >> $TEMP_ALBUM_LIST;
	done
	sort -k 1 -n $TEMP_ALBUM_LIST | sed 's/^[^ ]* //g' | sed 's$'"$MUSIC_FOLDER"'$'"$ADB_DESTDIR"'$' | sed '/^$/d' >> $PLAYLIST
done

rm $TEMP_ALBUM_LIST

echo $'\e[34m'"pushing to device from"$'\e[0m' $MUSIC_FOLDER
echo "adb push $MUSIC_FOLDER/* $ADB_DESTDIR"

# Only push if MUSIC_FOLDER has content
files=($MUSIC_FOLDER/*)
(($#files == 0)) || adb push $MUSIC_FOLDER/* $ADB_DESTDIR
