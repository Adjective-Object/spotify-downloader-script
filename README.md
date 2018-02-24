## Usage
1. Install [spotdl.py](https://github.com/ritiek/spotify-downloader)
2. Update `SPOTDL` in `dl.sh` to point to the spotdl command on your machine
3. Update `ADB_DESTDIR` in `dl.sh` to point to the destination directory the
   music should be copied to on your phone

## Building a list of albums
```
./search.sh [search args]
```
Args will be put into a list file based on the current day
(`./YYYY-MM-DD-automatic.txt`)

## Downloading a list of albums
```
./dl.sh [path to list]
```
Music files will be placed in `./dl/music-[list-file-name]/album-name/...`.



