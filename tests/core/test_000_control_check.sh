#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests for the make-checks.sh script

# GLOBALS
readonly MY_DIR=$(dirname $(readlink --canonicalize --verbose ${BASH_SOURCE[0]}))
readonly BASE_DIR=$(readlink --canonicalize --verbose "${MY_DIR}/../..")
readonly CHECK_SCRIPT='make-checks.sh'

function main() {
# Set up environment
	setup || return $?
# Checks script
	check_script || return $?

	test_log 'make-checks' OK
}

# Sets up environment within out test dir
# (artifacts and environment variables)
# shopt outside the function.
# See https://unix.stackexchange.com/questions/787437/weird-behaviour-on-bash-function
function setup() {
# Sets sources
	test_title ''
	export REPO_DIR="${HOME}/sourcecode"
	mkdir --parents "${REPO_DIR}"

	# not using cp --archive to avoid dreaded "can't copy a directory into itself" on older coreutils versions
	for target in $(
		find "${BASE_DIR}/" \
		-mindepth 1 -maxdepth 1 \
		\( -path */.git -or -path */tests \) \
		-prune -o -print
	); do
		cp --archive "${target}" "${REPO_DIR}/"
	done

# Sets install dir
	mkdir --parents "${HOME}/bin" || return $?
	PATH="${HOME}/bin:${PATH}"

# 	export SRCDIR="${REPO_DIR}/src"
# 	export BUILDDIR="${REPO_DIR}/build"
# 	export BME_BASENAME='bash-magic-enviro'
# 	export VERSION_FILE="${BME_BASENAME}.version"
	export DESTDIR="${HOME}/bin"

	test_log 'Sources setup' OK
}


function check_script() {
	test_title ''
	check_output=$("${REPO_DIR}/${CHECK_SCRIPT}") || {
		local rc=$?
		local err_msg="(${rc}) ${T_BOLD}error output:${T_NC}\n"
		err_msg+="${check_output}"
		test_log "${err_msg}" error
		unset check_output
		return $rc
	}
	unset check_output

	test_log 'Check script' OK
}

main; exit $?
