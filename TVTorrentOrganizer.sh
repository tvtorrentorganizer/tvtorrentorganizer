#!/bin/bash
#A simple Bash 4 script to rename and organize shows in the format 
#Show Name S##E##.extension
#USE AT YOUR OWN RISK, I PROVIDE NO WARRANTY. BACKUP YOUR MEDIA AND TEST BEFORE DEPLOYING!
#Could probably be rewritten using sed instead of Bash 4 string manipulations for better 
#portability but I'm not planning on taking on that project
#Specify where your show downloads are stored, where you would like your organized
#show folders to be stored, and a location to store any trashed directories
#This program will not delete anything, if it's not where it should be, it's in the trash
#directory you specify. EXCEPTION: If a file or directory already exists where the script
#tries to move something, it will rename the original to original.bak and move the new file
#over. HOWEVER, it will only make one backup of the original. If the script runs again and
#has to backup a current file again, it will overwrite the first backup. Basically, it will 
#prevent you from having 3 copies of the same show.
#The script will pull all mkv,mp4,mov and avi files out of the "downloads_location"
#directoy and subdirectories, move any subdirectories which contained those files to the
#"trash_location" INCLUDING any non video files like nfo,txt,srt,sub,etc.
#It will then exctract the show's name, season number, episode number and file extension
#From which, it will create a folder with the show's name (if one does not exist) and move
#The renamed video file to that folder.
#This was designed to be used with shows automatically downloaded with ShowRSS.info
#This will only work if the show's name is at the beginning of the original file name
#followed by the shows episode and season numbers in s##e## format. Almost all torrent
#release groups release their shows in this format so that should not be an issue.
#However, it does not consult any sort of internet DB. So if you have show files named
#1.avi or S05E03.mkv it will not be able to determine The name of the show and will most
#likely throw up an error.
#Very little error handling was incorporated into this script. USE AT YOUR OWN RISK!
#NOTE: The show_location you specify should only contain shows within it and its
#subdirectories. Do not point this at a general media download folder because it won't know
#how to handle the movies.
#NOTE 2: Your "shows_location" directory is where this program will create folders and
#store processing and processed files. This folder should not be a subdirectory of your
#"downloads_location" because anything in your "downloads_location" and any subdirectory
#further down it's chain will be processed. If you have a large media collection this could
#waste an enourmous ammount of time and possibly result in an infinite loop depending on
#how the find command loops, I have not tested this and do not recommend it.

#Specify the folder your show downloads are in
downloads_location="~/Downloads/Shows"
#Specify the folder you would like your organized show folders in
shows_location="~/Media/Shows"
#Specify the folder you would like this script to move any non video files after processing
trash_location="~/Trash"

#If it doesn't already exist, make a folder to move video files to before processing
mkdir -p "$shows_location/tmp"
processing="$shows_location/tmp"

#Change directories to the downloads_location
cd "$downloads_location"

#Find all files with mkv,mp4,avi,and mov extensions and move them to the temporary folder
#If those files were in a subdirectory of downloads_location, move the subdirectory to
#the trash_location
find . -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" -o -name "*.mov" \) -print0 | while read -d '' -r file; do 
	dir=${file%/*}
	cd "$dir" > /dev/null 2>&1
	mv -b --suffix=.bak *.{mkv,avi,mov,mp4} "$processing" > /dev/null 2>&1
	cd "$downloads_location"
	if [ "$dir" != "." ] 
	then
		mv -b "$dir" "$trash_location" > /dev/null 2>&1
	fi
done

#Change directories to the temporary folder that all the video files were moved to above
cd "$processing"

#Loops through all files in the temporary folder
find . -type f -print0 | while read -d '' -r filename; do
	file=${filename#*/} #Strip off the ./ at the beginning of the file name
	show=${file%[s,S][0-9]*} #Strip off everything from s(or S)# to the end of the filename
	show=${show//./ } #Change all . to spaces
	show=${show//-/ } #Change all - to spaces
	show=${show//_/ } #Change all _ to spaces
	#Capitalize the first letter of each word in the show name
	#This is not perfect because it doesn't account for acronyms like US or UK
	show=$(echo $show | tr '[A-Z]' '[a-z]' | sed 's/\(^\| \)\([a-z]\)/\1\u\2/g')
	
	season=${file%[e,E][0-9]*} #Grab the file name and strip everything from e(or E)#
	season=${season// /.} #Convert all spaces to .
	season=${season##*.} #Strip everything from the beginning to the last .
	season=${season#*[s,S]} #Strip off the s(or S)
	
	episode=${file#*[s,S][0-9][0-9][e,E]} #Strips everything from beginning through s##e
	episode=${episode// /.} #Converts all spaces to .
	episode=${episode%%.*} #Strips everything from the end through the first .
	
	ext=${file##*.} #Strips everything from the beginning through the last .
	
	pretty_title="$show S$season""E$episode"".$ext" #Formats the show in Show S##E##.ext
	
	#Creates a directory in shows_location with show's title, if directory does not exist
	mkdir -p "$shows_location/$show"
	
	#Renames show and moves it to the show directory
	mv -b --suffix=.bak "$file" "$shows_location/$show/$pretty_title"
done

#Once processing is complete, moves the processing folder to the trash_location
mv -b "$processing" "$trash_location"
