#!/usr/bin/env bash
shopt -s nullglob

readonly TESTS_DIR=$(dirname $(realpath "${BASH_SOURCE[0]}"))
readonly SCRIPT="${SCRIPT:-bash-magic-enviro}"
readonly BUILD_DIR="${BUILD_DIR:-${TESTS_DIR}/../build}"
readonly MODULES_DIR="${MODULES_DIR:-${BUILD_DIR}/${SCRIPT}_modules}"

#--
# HELPER FUNCTIONS
#--
# Strip ANSI escape codes/sequences [$1: input string, $2: target variable]
function strip_escape_codes() {
local _input="$1" _i _char _escape=0
local -n _output="$2"; _output=""

	for (( _i=0; _i < ${#_input}; _i++ )); do
		_char="${_input:_i:1}"
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
		_output+="${_char}"
	done
}
export -f strip_escape_codes


#--
# MAIN
#--
# Checking environment
[ -d "${BUILD_DIR}" ] || {
	err_msg="ERROR: no build dir '${BUILD_DIR}' found!\n"
	err_msg+="\tDid you forget running 'make build'?"
	echo -e "${err_msg}"
	exit 1
}

[ -d "${BUILD_DIR}/${SCRIPT}_modules" ] || {
	err_msg="ERROR: no build dir '${BUILD_DIR}/${SCRIPT}_modules' found!\n"
	err_msg+="\tDid you forget running 'make build'?"
	echo -e "${err_msg}"
	exit 1
}

echo "BUILD DIR: '${BUILD_DIR}'" && export BUILD_DIR
echo "MODULES DIR: '${MODULES_DIR}'" && export MODULES_DIR
echo -e "RUNNING TESTS ON '${TESTS_DIR}/'\n" && export TESTS_DIR

# Run tests
cd "${TESTS_DIR}"
export SCRATCH_DIR="${TESTS_DIR}/scratch"
rm --recursive --force "${SCRATCH_DIR}"

for test in test_*.sh; do
	echo "RUNNING '${test}'"
	mkdir --parents "${SCRATCH_DIR}"
	"./${test}" || test_rc=$?
	if [ -n "${test_rc}" ]; then
		err_msg="ERROR RUNNING '${test}'\n"
		err_msg+="\texit code: '${test_rc}'"
		echo -e "${err_msg}"
		exit $test_rc
	else
		unset test_rc
		rm --recursive --force "${SCRATCH_DIR}"
	fi
done
echo "ALL TESTS ENDED OK"
