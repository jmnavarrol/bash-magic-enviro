#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests for the make-control-install.sh script

# GLOBALS
readonly MY_DIR=$(dirname $(readlink --canonicalize --verbose ${BASH_SOURCE[0]}))
readonly BASE_DIR="${MY_DIR}/../.."
readonly INSTALL_SCRIPT="${BASE_DIR}/make-control-install.sh"

function main() {
# Check we can reach the install script
	INSTALL_SCRIPT_PATH=$(
		readlink --canonicalize-existing \
			--verbose \
			"${INSTALL_SCRIPT}" 2>&1
	) || {
		local rc=$?
		local realpath=$(realpath --canonicalize-missing "${INSTALL_SCRIPT}")
		local err_msg="($rc) Couldn't find install script at '${realpath}'\n"
		err_msg+="${INSTALL_SCRIPT_PATH}"
		test_log "${err_msg}" error 2
		return $rc
	}

# Set up environment
	mkdir --parents "${HOME}/sourcecode" || return $?

	cp --recursive --archive \
		"${BASE_DIR}/src" \
		"${HOME}/sourcecode/" || return $?
	export SRCDIR="${HOME}/sourcecode/src"

	cp --recursive --archive \
		"${BASE_DIR}/build" \
		"${HOME}/sourcecode/" || return $?
	export BUILDDIR="${HOME}/sourcecode/build"

	export BME_BASENAME='bash-magic-enviro'
	export VERSION_FILE="${BME_BASENAME}.version"
	export DESTDIR="${HOME}/bin"

	"${INSTALL_SCRIPT}" install || return $?

	echo "HOME CONTENTS:"
	tree -a "${HOME}"

	unset SRCDIR BME_BASENAME VERSION_FILE BUILDDIR DESTDIR
	test_log "make-control-install.sh" OK 0
}

main; exit $?
