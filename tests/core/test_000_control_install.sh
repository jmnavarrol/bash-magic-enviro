#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests for the make-control-install.sh script

# GLOBALS
readonly MY_DIR=$(dirname $(readlink --canonicalize --verbose ${BASH_SOURCE[0]}))
readonly BASE_DIR=$(readlink --canonicalize --verbose "${MY_DIR}/../..")
readonly INSTALL_SCRIPT='make-control-install.sh'

function main() {
# Set up environment
	setup || return $?
# Check script params
	check_install || return $?
	check_uninstall || return $?

	test_log "${INSTALL_SCRIPT}" OK 0
}

# Sets up environment within out test dir
# (artifacts and environment variables)
# shopt outside the function.
# See https://unix.stackexchange.com/questions/787437/weird-behaviour-on-bash-function
shopt -s extglob dotglob
function setup() {
	test_title ''
	export REPO_DIR="${HOME}/sourcecode"
	mkdir --parents "${REPO_DIR}"
	shopt -s extglob dotglob
	cp --archive --recursive "${BASE_DIR}"/!(tests|.git) "${REPO_DIR}/"
	shopt -u extglob dotglob

	export SRCDIR="${REPO_DIR}/src"
	export BUILDDIR="${REPO_DIR}/build"
	export BME_BASENAME='bash-magic-enviro'
	export VERSION_FILE="${BME_BASENAME}.version"
	export DESTDIR="${HOME}/bin"

	test_log 'Sources setup' OK
}
shopt -u extglob dotglob


function check_install() {
	test_title ''
	install_output=$("${REPO_DIR}/${INSTALL_SCRIPT}" install) || {
		local rc=$?
		local err_msg="(${rc}) ${T_BOLD}error output:${T_NC}\n"
		err_msg+="${install_output}"
		test_log "${err_msg}" error
		return $rc
	}
# Check that expected outputs are in place
# 	tree -a "${HOME}"
	if [ ! -r "${REPO_DIR}/.installdir" ]; then
		local err_msg="${T_BOLD}install${T_NC}:\n"
		err_msg+="\tCouldn't find ${T_BOLD}'${REPO_DIR}/.installdir'${T_NC}.\n"
		err_msg+="${install_output}"
		test_log "${err_msg}" error
		unset install_output
		return 1
	fi
	unset install_output
	test_log 'install' OK
}

function check_uninstall() {
	test_title ''
	uninstall_output=$("${REPO_DIR}/${INSTALL_SCRIPT}" uninstall) || {
		local rc=$?
		local err_msg="(${rc}) ${T_BOLD}error output:${T_NC}\n"
		err_msg+="${uninstall_output}"
		test_log "${err_msg}" error
		return $rc
	}
	echo -e "${uninstall_output}"
# Check results
	for bme_file in "${DESTDIR}/${BME_BASENAME}" "${DESTDIR}/${VERSION_FILE}"; do
		if [ -f "${bme_file}" ]; then
			local err_msg="${T_BOLD}uninstall${T_NC}:\n"
			err_msg+="\t${T_BOLD}'${bme_file}'${T_NC} shouldn't be there."
			test_log "${err_msg}" error
			return 1
		fi
	done

	unset uninstall_output
	test_log 'uninstall' OK
}

main; exit $?
