#!/bin/bash

# This script takes a git folder as argument and tries to find all files that
# are on the git ignore list and removes them from the repo.

# Exit if any command returns false
set -o errexit
# Exit if any variable is used unset
set -o nounset

if [ $# -ne 1 ]; then
	echo "Usage: $0 FOLDER.";
	false;
fi

FOLDER=$1

if [ ! -d $FOLDER ]; then
	echo "Folder $FOLDER not found."
	false;
fi

cd $FOLDER

if [ ! -d ".git" ]; then
	echo "Hmm, no git repository found. Maybe wrong folder?"
	false;
fi

GIT_STATUS=$(git status -uno --porcelain)

if [ ! -z "$GIT_STATUS" ]; then
	read -p "The repository is not clean. Do you want to proceed anyway? [y/N] "
	[ "$REPLY" != "y" ] && { false; }
fi

GITIGNORE_FILES=""

if [ -e ".gitignore" ]; then
	GITIGNORE_FILES="$GITIGNORE_FILES .gitignore";
fi

if [ -e "$HOME/.gitignore" ]; then
	GITIGNORE_FILES="$GITIGNORE_FILES $HOME/.gitignore";
fi

if [ -z "$GITIGNORE_FILES" ]; then
	echo "You have no gitignore files. Neither at $USER/.gitignore nor in the repo itself."
	exit -1
fi

FILESTOREMOVE=""

cat $GITIGNORE_FILES | grep -v "^$" | grep -v "^#" | while read line
do
	FILESTOREMOVE=$(find . -name "*$line*")
done

if [ -z "$FILESTOREMOVE" ]; then
	echo "No files to remove... Yippe"
	exit 0
fi

cat $FILESTOREMOVE | xargs git rm --caches --ignore-unmatch -r --

if [ ! -z "$GIT_STATUS" ]; then
	echo "Removed all files. You may want to git commit now"
fi

