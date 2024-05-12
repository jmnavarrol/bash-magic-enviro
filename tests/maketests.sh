#!/usr/bin/env bash

# Main "controller" for BME unit tests

readonly SCRIPT_FULL_PATH=$(realpath "${BASH_SOURCE[0]}")
readonly TESTS_DIR=$(dirname ${SCRIPT_FULL_PATH})

readonly BUILD_DIR="${BUILD_DIR:-${TESTS_DIR}/../build}"
readonly BME_BASENAME="${BME_BASENAME:-bash-magic-enviro}"
readonly BME_FULL_PATH="${BUILD_DIR}/${BME_BASENAME}"
export BME_FULL_PATH

check_environment() {
	[ -d "${BUILD_DIR}" ] || {
		local err_msg+="\tNo build dir ${C_BOLD}'${BUILD_DIR}'${C_NC} found!\n"
		local err_msg+="\tDid you forget running ${C_BOLD}'make build'${C_NC}?"
		bme_log "${err_msg}" error
		exit 1
	}
	[ -r "${BME_FULL_PATH}" ] || {
		local err_msg+="\tNo main script ${C_BOLD}'${BME_FULL_PATH}'${C_NC} found!\n"
		local err_msg+="\tDid you forget running ${C_BOLD}'make build'${C_NC}?"
		bme_log "${err_msg}" error
		exit 1
	}
	[ -d "${BME_FULL_PATH}_modules" ] || {
		local err_msg+="\tNo modules dir ${C_BOLD}'${BME_FULL_PATH}_modules'${C_NC} found!\n"
		local err_msg+="\tDid you forget running ${C_BOLD}'make build'${C_NC}?"
		bme_log "${err_msg}" error
		exit 1
	}
}

# Strips ANSI escape codes/sequences
# $1 message to sanitize
function strip_escape_codes() {
local raw_input="${1}"
local stripped_output=''
# locals for each line
local _i _char _escape=0

	for line in "${raw_input}"; do
		local stripped_line=''
		for (( _i=0; _i < ${#line}; _i++ )); do
			_char="${line:_i:1}"
			if (( ${_escape} == 1 )); then
				if [[ "${_char}" == [a-zA-Z] ]]; then
					_escape=0
				fi
				continue
			fi
			if [[ "${_char}" == $'\e' ]]; then
				_escape=1
				continue
			fi
			stripped_line+="${_char}"
		done
		stripped_output+="${stripped_line}"
	done

	echo -en "${stripped_output}"
}
export -f strip_escape_codes

#--
# MAIN
#--
if [ -z "${CONTROL_VAR}" ]; then
# running script "from the outside"
	check_environment

# call back the script for each test file in a loop within a clean environment
	cd "${TESTS_DIR}"
	for test in test_*.sh; do
		env --ignore-environment \
			CONTROL_VAR='set' \
			VIRTUALENVWRAPPER_SCRIPT="${VIRTUALENVWRAPPER_SCRIPT}" \
			"${SCRIPT_FULL_PATH}" "${test}" || exit $?
	done
else
# "inner run" on a clean environment: run the test script I got as first param
	test_script="${1}"

	export SCRATCH_DIR="${TESTS_DIR}/scratch"
	export HOME="${SCRATCH_DIR}"
	export BME_HIDDEN_DIR="${BME_HIDDEN_DIR}"
	source "${BME_FULL_PATH}" >/dev/null || exit $?

	if [ -n "${test_script}" ] \
	&& [ -x "${test_script}" ] ; then
		bme_log "Running tests on ${C_BOLD}'${TESTS_DIR}/${test_script}'${C_NC}..." info
		rm --recursive --force "${SCRATCH_DIR}" && mkdir --parents "${SCRATCH_DIR}"

		"./${test_script}" || test_rc=$?
		if [ -n "${test_rc}" ]; then
			err_msg="Running ${C_BOLD}'${TESTS_DIR}/${TESTS_DIR}/${test}'${C_NC}\n"
			err_msg+="\texit code: ${C_BOLD}'${test_rc}'${C_NC}"
			bme_log "${err_msg}" error
			exit $test_rc
		else
			rm --recursive --force "${SCRATCH_DIR}"
			bme_log "${C_BOLD}'${TESTS_DIR}/${test_script}'${C_NC}" 'OK'
		fi
	else
		bme_log "couldn't run test script '${test_script}'." error
		exit 1
	fi
fi
