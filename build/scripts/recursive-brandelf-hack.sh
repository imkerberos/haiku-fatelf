#!/bin/sh

# This script recursively rebrands shared libraries and static archives using
# the elfbrand tool.
#
# This is a temporary fix until (if!) GCC4 binaries are rebuilt with the 
# appropriate OSABI value.

AR="`pwd`/generated/cross-tools/i586-pc-haiku/bin/ar"
BRANDELF=`which elfbrand`
if [ $? != 0 ]; then
	# Try the Mac OS X path
	BRANDELF=`which elftc-brandelf`
	if [ $? != 0 ]; then
		echo "Could not find a valid elfbrand executable"
		exit 0;
	fi
fi

TARGET="$1"
BRAND="$2"

if [ -z "${TARGET}" ] || [ -z "${BRAND}" ]; then
	echo "Usage: $0 <target dir> <ELF brand>"
	exit 1
fi

find "${TARGET}" -type f -name '*.so' -exec "${BRANDELF}" -f "${BRAND}" {} \;
find "${TARGET}" -type f -name '*.a' -print0 | while IFS= read -r -d $'\0' file; do
	basefile=`basename "$file"`
	dir=`mktemp -d -t "$basefile.XXXXX"`
	if [ $? != 0 ]; then
		echo "Failed to create temporary directory"
	fi
	pushd "${dir}" >/dev/null
	"${AR}" x "${file}"
	popd "${dir}" >/dev/null
	find "${dir}" -name '*.o' -exec "${BRANDELF}" -f "${BRAND}" {} \;
	"${AR}" r "${file}" "${dir}/"*.o
done
