#! /bin/bash

# whatever this script generates will be shown as a caption

if [[ "`which exiv2`" == "" ]] ; then
	date +%l:%m%p
	echo "$2"
else
	exiv2 -g Exif.Photo.UserComment -P t $1
fi
