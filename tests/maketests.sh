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
local test_start=$(date +%s)

# List of tests to run
	declare -a tests_list=()
	# Find all tests under tests' root directory (default) or tests found within given argument(s)
	for argument in "${@:-$TESTS_DIR}"; do
		argument=$(realpath --canonicalize-existing "${argument}") || exit $?
		tests_list+=(
			$(
				find "${argument}" -type f -executable -name test_*.sh \
				| sort --numeric-sort
			)
		)
	done

# Go with tests
	source "${TESTS_DIR}/helper_functions.sh" || exit $?

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
		local batch_start=$(date +%s)
		env --ignore-environment \
			PATH="$(realpath "${BUILDDIR}"):/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin" \
			HOME="${test_scratch_dir}" \
			CURRENT_TESTFILE_NUMBER=${test_counter} \
			bash -c "source "${TESTS_DIR}/helper_functions.sh" && ${test}"
	# Now, check result from command above
		local test_rc=$?
		local batch_duration=$( seconds_duration $(( $(date +%s)-batch_start )) )
		local batch_msg="${C_BOLD}${test_counter}. '${test}'${C_NC}\n"
		batch_msg+="\tbatch time: ${T_BOLD}${batch_duration}${T_NC}\n"
		if [ $test_rc -ne 0 ]; then
			batch_msg+="\t(${T_RED}${test_rc}${T_NC}) "
			batch_msg+="See both the output above and the contents of the test's scratch dir:"
			batch_msg+="\n\t\t'${T_BOLD}${test_scratch_dir}'${T_NC}\n"
			echo ''
			test_log "${batch_msg}" error 0
			break
		fi
	# Test finished OK; let's clean
		rm --recursive --force ${test_scratch_dir}
		test_log "${batch_msg}" ok 0
	done
	shopt -u nullglob globstar

	echo ''
	local final_msg="${T_BOLD}TEST BATCHES RUN:${T_NC} "
	if (( ${test_rc} == 0 )); then
		local final_status='info'
		rm --recursive --force ${test_scratch_dir}
		final_msg+="${T_GREEN}${test_counter}${T_NC}\n"
	else
		local final_status='fail'
		final_msg+="${T_YELLOW}${test_counter}${T_NC}\n"
	fi

	local elapsed_time=$( seconds_duration $(( $(date +%s)-test_start )) )
	final_msg+="\telapsed time: ${T_BOLD}${elapsed_time}${T_NC}"
	test_log "${final_msg}" "${final_status}" 0
	return ${test_rc}
}


# Makes sure the environment is ready for testing
function check_environment() {
	[ ${DEBUG:+1} ] && echo "BUILDDIR: '${BUILDDIR}'"
	[ -d ${BUILDDIR} ] || {
		local err_msg="BME code dir ${T_BOLD}'${BUILDDIR}'${T_NC} doesn't exist."
		err_msg+="\n\tDid you run ${T_BOLD}'make build'${T_NC}?"
		test_log "${err_msg}" error 0
		return 1
	}
	[ ${DEBUG:+1} ] && tree ${BUILDDIR} || return 0
}

#--
# ENTRY POINT
#--
main "$@"; exit $?
