# Exit if any command returns false
set -o errexit
# Exit if any variable is used unset
set -o nounset

# Only run when we are in release mode
[ $BUILD_STYLE = Release ] || { echo Distribution target requires "'Release'" build style; false; }

GIT=/usr/local/bin/git
CUT=/usr/bin/cut

GIT_STATUS=$($GIT status -uno --porcelain)

# Only run if the repository is clean.
[ ! -z $GIT_STATUS ] || { echo Repository is not clean. Please commit all your changes before deploying; false; }

# Set some product specific variables
VERSION="$CURRENT_PROJECT_VERSION"
SHORT_VERSION="$CURRENT_MARKETING_VERSION"
# Set the URL where the app can be downloaded. Used to generate Sparkle appcast snippet
DOWNLOAD_BASE_URL=""
# URL to the release notes. Also used for the Sprakle appcast snippet
RELEASENOTES_URL=""
# The deployment destination is used to generate an scp command at the end of the script
DEPLOYMENT_DESTINATION=""

ARCHIVE_FILENAME="$PROJECT_NAME $SHORT_VERSION.zip"

# Set the name of the note in your key chain that contains your private sparkle key
KEYCHAIN_PRIVKEY_NAME="Sparkle Private Key 1"

# Set the build revision to the current git commit hash
BUILD_REVISION=$($GIT log -1 --pretty=oneline --abbrev-commit | $CUT -c1-7)

/usr/libexec/PlistBuddy -c "Set :BuildRevision $BUILD_REVISION" ${TARGET_BUILD_DIR}/${INFOPLIST_PATH}

# Archive the product
WD=$PWD
cd "$BUILT_PRODUCTS_DIR"
rm -f "$PROJECT_NAME"*.zip
ditto -ck --keepParent "$PROJECT_NAME.app" "$ARCHIVE_FILENAME"

# Sign the archive
SIZE=$(stat -f %z "$ARCHIVE_FILENAME")
PUBDATE=$(LC_TIME=en_US date +"%a, %d %b %G %T %z")
SIGNATURE=$(openssl dgst -sha1 -binary < "$ARCHIVE_FILENAME" | openssl dgst -dss1 -sign <(security find-generic-password -g -s "$KEYCHAIN_PRIVKEY_NAME" 2>&1 1>/dev/null | perl -pe '($_) = /"(.+)"/; s/\\012/\n/g' | perl -MXML::LibXML -e 'print XML::LibXML->new()->parse_file("-")->findvalue(q(//string[preceding-sibling::key[1] = "NOTE"]))') | openssl enc -base64)

# Save the debug symbols
DWARF_DSYM_FILE=${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
DSYM_DEST_PATH=${PROJECT_DIR}/dSYM/${EXECUTABLE_NAME}.$PUBDATE.$BUILD_REVISION.dSYMs

mv "$DWARF_DSYM_FILE" "$DSYM_DEST_PATH"

$GIT add "$DSYM_DEST_PATH"
$GIT commit -m "Added dSYM file for build $BUILD_REVISION" "$DSYM_DEST_PATH"


[ $SIGNATURE ] || { echo Unable to load signing private key with name "'$KEYCHAIN_PRIVKEY_NAME'" from keychain; false; }

# return some useful snippets. One for the sparkle appcast and one to copy the file.
DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILENAME"

cat <<EOF
        <item>
            <title>Version $SHORT_VERSION</title>
            <sparkle:releaseNotesLink>$RELEASENOTES_URL</sparkle:releaseNotesLink>
            <pubDate>$PUBDATE</pubDate>
            <enclosure
                url="$DOWNLOAD_URL"
                sparkle:version="$VERSION"
                sparkle:shortVersionString="$SHORT_VERSION"
                type="application/octet-stream"
                length="$SIZE"
                sparkle:dsaSignature="$SIGNATURE"
            />
        </item>
EOF

echo scp "'$BUILT_PRODUCTS_DIR/$ARCHIVE_FILENAME'" "'$DEPLOYMENT_DESTINATION'"

