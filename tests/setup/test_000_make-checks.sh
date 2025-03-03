#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests for the make-checks.sh script

# GLOBALS
readonly CHECK_SCRIPT='make-checks.sh'

function main() {
# Set up environment
	mkdir --parents "${HOME}/bin" || return $?
	PATH="${HOME}/bin:${PATH}"
	export DESTDIR="${HOME}/bin"

# Checks check script
	check_script || return $?

	test_log 'make-checks' OK
}

# tests the check script
function check_script() {
	test_title ''
	check_output=$(
		"${SOURCES_DIR}/${CHECK_SCRIPT}"
	) || {
		local rc=$?
		local err_msg="(${rc}) ${T_BOLD}error output:${T_NC}\n"
		err_msg+="${check_output}"
		test_log "${err_msg}" error
		unset check_output
		return $rc
	}
	unset check_output
}

main; exit $?
