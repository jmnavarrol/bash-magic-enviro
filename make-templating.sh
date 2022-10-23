#!/bin/bash
# Template substitution (to be run from Makefile)
# translates <% VARIABLE %> into VARIABLE's value
#
# Expected environment variables:
# SRCDIR: directory holding source code
# SCRIPT: the name of the main script (which will be found at ${SRCDIR}/${SCRIPT})
# BUILDDIR: the output directory (output file will be ${BUILDDIR}/${SCRIPT})

# Gets current remote origin
REMOTE_GIT=`git ls-remote --get-url`

# Make sure the output directory exists and the output file is empty
mkdir -p "${BUILDDIR}"
cat /dev/null > "${BUILDDIR}/${SCRIPT}"

# Now process source file line by line
while IFS= read -r LINE; do
	# we want to substitute <% VARIABLE %> -> VARIABLE's value
	# regex explained by capture groups:
	#	1: (<%[[:space:]]*) -> finds the opening tag '<% ' (maybe with blanks)
	#	2: ([^[:space:]]+) -> the variable's name (everything which is not blank in between the markers)
	#	3: ([[:space:]]*%>) -> the closing tag ' %>' (maybe with blanks)
	if [[ "${LINE}" =~ (<%[[:space:]]*)([^[:space:]]+)([[:space:]]*%>) ]]; then
		echo -en "\t'${LINE}' -> "
		LINE=${LINE//${BASH_REMATCH}/\'${!BASH_REMATCH[2]}\'}
		echo -e "'${LINE}'"
	fi
	# Sends the line, modified if required, to output file
	echo "${LINE}" >> "${BUILDDIR}/${SCRIPT}"
done < "${SRCDIR}/${SCRIPT}"

echo -e "${C_BOLD}templating:${C_NC} ${C_GREEN}DONE${C_NC}."
