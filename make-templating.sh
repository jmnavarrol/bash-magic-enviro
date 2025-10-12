#!/usr/bin/env bash

# Template substitution (to be run from Makefile)
# translates <% VARIABLE %> into VARIABLE's value
#
# Expected environment variables:
# SRCDIR: directory holding source code
# VERSION_FILE: the name of templated file (its source will be found at ${SRCDIR}/${VERSION_FILE}.tpl)
# BUILDDIR: the output directory (output file will be ${BUILDDIR}/${SCRIPT})

# Gets current remote origin
readonly DEFAULT_REMOTE_GIT="${DEFAULT_REMOTE_GIT:=https://github.com/jmnavarrol/bash-magic-enviro.git}"
REMOTE_GIT=`git ls-remote --get-url`

readonly MANDATORY_VARS=(
	'SRCDIR'
	'BUILDDIR'
	'VERSION_FILE'
)
readonly TEMPLATE_FILE="${SRCDIR}/${VERSION_FILE}.tpl"
readonly OUTPUT_FILE="${BUILDDIR}/${VERSION_FILE}"

# Checks environment
for mandatory_var in ${MANDATORY_VARS[@]}; do
	if [ -z "${!mandatory_var}" ]; then
		echo -e "${C_RED}ERROR:${C_NC} Mandatory environment variable ${C_BOLD}'${mandatory_var}'${C_NC} is unset or empty."
		exit 1
	fi
done

# Checks proper git remote (for builds that don't come from a git clone)
[ -n "${REMOTE_GIT}" ] || REMOTE_GIT="${DEFAULT_REMOTE_GIT}"

# Make sure the output directory exists and the output file is empty
# mkdir -p "${BUILDDIR}"
cat /dev/null > "${OUTPUT_FILE}"

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
	echo "${LINE}" >> "${OUTPUT_FILE}"
done < "${TEMPLATE_FILE}"

echo -e "${C_BOLD}templating:${C_NC} ${C_GREEN}DONE${C_NC}."
