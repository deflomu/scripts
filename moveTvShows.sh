#!/bin/sh

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
                break
        fi
        newPath=`echo $filename| sed 's/^\([a-zA-Z.]*\)\.[S|[:digit:]].*/\1/'| tr -s '.' ' '`
        logger -t $0 Moving $filename to $TVSHOWS_FOLDER/$newPath/
        if [ ! -d "$TVSHOWS_FOLDER/$newPath" ]; then
                logger -t $0 $TVSHOWS_FOLDER/$newPath does not exist. Creating it...
                mkdir -p "$TVSHOWS_FOLDER/$newPath"
        fi
        mv $filename "$TVSHOWS_FOLDER/$newPath/$filename"
done

