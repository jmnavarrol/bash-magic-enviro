#!/usr/bin/env bash

# Set DEBUG to any value for debugging purposes
# DEBUG=1

#--
# CONFIG
#--
readonly SCRIPT_FULL_PATH=$(realpath "${BASH_SOURCE[0]}")
readonly TESTS_DIR=$(dirname ${SCRIPT_FULL_PATH})
readonly SCRATCH_BASE_DIR="${TESTS_DIR}/scratch"

BUILDDIR="${BUILDIR:-${TESTS_DIR}/../build}"  # BME build directory ("compiled" sources)


# Main "controller" for BME unit tests
# The idea is to run each test script within an isolated environment.
#
# It can get a list of tests to run as parameter
function main() {
local test_counter=0

# list of tests to run
	if (( ${#} > 0 )); then
		tests_list="${@}"
	else
		tests_list=( ${TESTS_DIR}/**/test_*.sh )
	fi

	source "${TESTS_DIR}/helper_functions.sh"

	[ ${DEBUG:+1} ] && echo "DEBUGGING IS ACTIVE" # debugging example
	check_environment || exit $?

	test_log "${C_BOLD}RUNNING UNITARY TESTS...${C_NC}" info 0
	# call back on each test within a clean environment
	# nullglob avoids 'match on asterisk' if no file is found
	shopt -s nullglob globstar
	for test in "${tests_list[@]}"; do
		[ -x "${test}" ] || {
			test_log "${T_BOLD}'${test}'${T_NC} is not executable.  Stopping here." error 0
			exit 1
		}

		[ ${DEBUG:+1} ] && echo -e "\tFOUND TEST FILE '${test}'"
		test_log "\n${T_BOLD}$((++test_counter)). '${test}'${T_NC}..." '' 0

		local padded_random=$(printf "%03d\n" $((0 + $RANDOM % 999)))
		local test_scratch_dir="${SCRATCH_BASE_DIR}/test_${padded_random}"
		[ ${DEBUG:+1} ] && test_log "TEST's scratch dir: '${test_scratch_dir}'"
		mkdir --parents ${test_scratch_dir}
		env --ignore-environment \
			PATH="$(realpath "${BUILDDIR}"):/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin" \
			HOME="${test_scratch_dir}" \
			CURRENT_TESTFILE_NUMBER=${test_counter} \
			bash -c "source "${TESTS_DIR}/helper_functions.sh" && ${test}"
	# Now, check result from command above
		local test_rc=$?
		if [ $test_rc -ne 0 ]; then
			local err_msg="${C_BOLD}'${test}'${C_NC} (${test_rc})"
			err_msg+="\n\tSee both the output above and the contents of the test's scratch dir:"
			err_msg+="\n\t\t'${T_BOLD}${test_scratch_dir}'${T_NC}\n"
			err_msg+="\n${C_BOLD}UNITARY TEST BATCHES RUN: ${C_YELLOW}${test_counter}${C_NC}."
			echo ''
			test_log "${err_msg}" error 0
			exit $test_rc
		fi
	# Test finished OK; let's clean
		rm --recursive --force ${test_scratch_dir}
	done
	shopt -u nullglob globstar
	# Finally, delete the "main" scratch dir
	rm --recursive --force ${test_scratch_dir}
	echo ''
	test_log "${C_BOLD}UNITARY TEST BATCHES RUN: ${C_GREEN}${test_counter}${C_NC}." info 0
}


# Makes sure the environment is ready for testing
function check_environment() {
	[ ${DEBUG:+1} ] && echo "BUILDDIR: '${BUILDDIR}'"
	[ -d ${BUILDDIR} ] || {
		echo "ERROR: BME code dir '${BUILDDIR}' doesn't exist."
		echo -e "\tDid you run 'make build'?"
		return 1
	}
	[ ${DEBUG:+1} ] && tree ${BUILDDIR} || return 0
}

#--
# ENTRY POINT
#--
main "$@"; exit $?
