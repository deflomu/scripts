#!/bin/sh

logger -t $0 Starting...

DOWNLOAD_FOLDER=/tmp/mounts/Elements/Serien/Unsortiert
TVSHOWS_FOLDER=/tmp/mounts/Elements/Serien

if [ ! -d "$DOWNLOAD_FOLDER" ]; then
        logger -t $0 $DOWNLOAD_FOLDER does not exist. Exiting
        exit
fi

cd $DOWNLOAD_FOLDER
ls -1 |
while read filename; do
        extension=${filename##*.}
        if [ $extension == "part" ]; then
                continue
        fi

        # First replace all _ and whitespace chars with . to get consistent filenames
        newFilename=`echo "$filename" | sed 's/[_ ]/./g' | sed 's/\.\W\././g'`
        newPath=`echo $newFilename | sed 's/^\([a-zA-Z.]*\)\.[S|[:digit:]].*/\1/'| tr -s '.' ' '`
        logger -t $0 Moving $filename to $TVSHOWS_FOLDER/$newPath/$newFilename
        if [ ! -d "$TVSHOWS_FOLDER/$newPath" ]; then
                logger -t $0 $TVSHOWS_FOLDER/$newPath does not exist. Creating it...
                mkdir -p "$TVSHOWS_FOLDER/$newPath"
        fi
        mv "$filename" "$TVSHOWS_FOLDER/$newPath/$newFilename"
done

logger -t $0 Done

