#! /bin/bash

# whatever this script generates will be shown as a caption

if [[ "`which exiv2`" == "" ]] ; then
	date +%l:%m%p
	echo "$*"
else
	exiv2 -g Exif.Photo.UserComment -P t %f
fi