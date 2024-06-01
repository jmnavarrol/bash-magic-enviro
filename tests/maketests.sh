#!/usr/bin/env bash

#--
# CONFIG
#--
readonly SCRIPT_FULL_PATH=$(realpath "${BASH_SOURCE[0]}")
readonly TESTS_DIR=$(dirname ${SCRIPT_FULL_PATH})
readonly SCRATCH_DIR="${TESTS_DIR}/scratch"


# Main "controller" for BME unit tests
# The idea is to run each test script within an isolated environment.
# For this to happen, a control var is checked:
# if not set, we are running on the "outside" of the control environment;
# if already set, we are within a clean environment where we can run tests within
function main() {
	if [ -z "${TESTS_CONTROL_VAR}" ]; then
	# still running "on the outside"
		check_environment || exit $?

		# call back on each test within a clean environment
		# nullglob avoids 'match on asterisk' if no file is found
		shopt -s nullglob globstar
		for test in ${TESTS_DIR}/**/test_*.sh; do
			mkdir "$SCRATCH_DIR"
			env --ignore-environment \
				TESTS_CONTROL_VAR='set' \
				SCRATCH_DIR="${SCRATCH_DIR}" \
				BUILDDIR=$(realpath "${BUILDDIR}") \
				VIRTUALENVWRAPPER_SCRIPT="${VIRTUALENVWRAPPER_SCRIPT}" \
				"${SCRIPT_FULL_PATH}" "${test}" || test_rc=$?

		# check test result
			if [ -n "${test_rc}" ]; then
				echo "ERROR RUNNING TEST (${test_rc}): '${test}'"
				exit $test_rc
			else
				rm --recursive --force "$SCRATCH_DIR"
			fi
		done
		shopt -u nullglob globstar
	else
	# "inner run" within a clean environment
		local test_script="${1}"
		echo "RUNNING TEST: '${test_script}'"
		${test_script} || exit $?
	fi
}


# Makes sure the environment is ready for testing
function check_environment() {
local mandatory_env_vars=(
	'BUILDDIR'
	'VIRTUALENVWRAPPER_SCRIPT'
)

# Checks environment variables
	for envvar in "${mandatory_env_vars[@]}"; do
		if [ -z "${!envvar}" ]; then
			echo "MANDATORY ENVIRONMENT VARIABLE '${envvar}' UNDEFINED!"
			return 1
		fi
	done
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
# ENTRY POINT
#--
main "$@"
