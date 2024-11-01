#!/usr/bin/env bash

# Set DEBUG to any value for debugging purposes
# DEBUG=1

#--
# CONFIG
#--
readonly SCRIPT_FULL_PATH=$(realpath "${BASH_SOURCE[0]}")
readonly TESTS_DIR=$(dirname ${SCRIPT_FULL_PATH})
readonly SCRATCH_DIR="${TESTS_DIR}/scratch"

BUILDDIR="${BUILDIR:-${TESTS_DIR}/../build}"  # BME build directory ("compiled" sources)


# Main "controller" for BME unit tests
# The idea is to run each test script within an isolated environment.
function main() {
local test_counter=0

	[ ${DEBUG:+1} ] && echo "DEBUGGING IS ACTIVE" # debugging example
	check_environment || exit $?

	source "${BUILDDIR}/bash-magic-enviro"
	bme_log "${C_BOLD}RUNNING UNITARY TESTS...${C_NC}" info
	# call back on each test within a clean environment
	# nullglob avoids 'match on asterisk' if no file is found
	shopt -s nullglob globstar
	for test in ${TESTS_DIR}/**/test_*.sh; do
		[ ${DEBUG:+1} ] && echo -e "\tFOUND TEST FILE '${test}'"
		bme_log "\n${C_BOLD}$((++test_counter)). '${test}'${C_NC}..."

		local padded_random=$(printf "%03d\n" $((0 + $RANDOM % 999)))
		local test_scratch_dir="${SCRATCH_DIR}/test_${padded_random}"
		[ ${DEBUG:+1} ] && echo -e "\tTEST's scratch dir: '${test_scratch_dir}'"
		mkdir --parents ${test_scratch_dir}
		env --ignore-environment \
			BUILDDIR=$(realpath "${BUILDDIR}") \
			SCRATCH_DIR="${test_scratch_dir}" \
			bash -c "source "${TESTS_DIR}/helper_functions.sh" && ${test}"
	# Now, check result from command above
		local test_rc=$?
		if [ $test_rc -ne 0 ]; then
			bme_log "${C_BOLD}'${test}'${C_NC} (${test_rc})" error
			echo -e "See both the output above and the contents of the test's scratch dir:"
			echo -e "\t'${test_scratch_dir}'\n"
			bme_log "${C_BOLD}UNITARY TESTS RUN: ${C_YELLOW}${test_counter}${C_NC}." error
			exit $test_rc
		fi
	# Test finished OK; let's clean
		rm --recursive --force ${test_scratch_dir}
	done
	shopt -u nullglob globstar
	# Finally, delete the "main" scratch dir
	rm --recursive --force ${SCRATCH_DIR}
	echo ''
	bme_log "${C_BOLD}UNITARY TESTS RUN: ${C_GREEN}${test_counter}${C_NC}." info
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
