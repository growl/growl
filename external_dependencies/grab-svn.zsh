#!/bin/zsh -f

#Download an unversioned copy of the files from a svn repository
#Usage: grab-svn url commit-ID destination
#The files will exist in a folder under the destination name.
#A file in the same folder named .svn_commit_id will contain the commit ID of the version you grabbed. This is mainly useful when you're re-grabbing unchanged source with an updated commit ID, such as after a rebase.

svn_url="$1"
svn_commit_id="$2"
svn_destination="$3"

if test -e "$svn_destination"; then
	echo "$svn_destination already exists here - aborting" >> /dev/stderr
	exit 1
fi

svn export -r $svn_commit_id $svn_url $svn_destination
echo "$svn_commit_id" > "$svn_destination/.svn_commit_id"
