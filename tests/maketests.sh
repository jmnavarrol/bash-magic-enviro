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

# First, clean possible previous "dirty" test environment
	rm -rf "${SCRATCH_BASE_DIR}"

	source "${TESTS_DIR}/helper_functions.sh" || exit $?

# List of components to search for
	declare -a tests_list=()
	if (( $# > 0 )); then
	# find tests within given arguments
		for argument in "${@}"; do
			search_path+=("${argument}")
		done
	else
	# no arguments: standard test list
		for argument in "${TESTS_DIR}"/{setup,core,modules}; do
			search_path+=("${argument}")
		done
	fi

# Find all tests under the components list
	for argument in "${search_path[@]}"; do
			abs_argument=$(realpath --canonicalize-existing "${argument}") || {
				argument=$(realpath --canonicalize-missing "${argument}")
				local err_msg="'${argument}' can't be found."
				test_log "${err_msg}" fatal 0
				exit $?
			}
			tests_list+=(
				$(
					find "${abs_argument}" -type f -executable -name test_*.sh \
					| sort --numeric-sort
				)
			)
	done
	if (( ${#tests_list[@]} == 0 )); then
		printf -v list_of_paths '%s, ' "${search_path[@]}"
		test_log "no tests were found at [${list_of_paths%, }]" warning 0
		exit 0
	fi

	[ ${DEBUG:+1} ] && echo "DEBUGGING IS ACTIVE" # debugging example
# Makes sure artifacts are up to date
	check_environment || exit $?
	(
		cd ${TESTS_DIR}/../ && make build
	)

	test_log "${C_BOLD}RUNNING UNITARY TESTS...${C_NC}" info 0

# Creates reusable templates
	rm -rf "${SCRATCH_BASE_DIR}"  # in case there was a previous failure
	local sources_template="${SCRATCH_BASE_DIR}/sources_template"
	local installed_template="${SCRATCH_BASE_DIR}/installed_template"
	# only sources first
	if ! [ -d "${sources_template}" ]; then
		mkdir --parents "${sources_template}/sources" || return $?
		for target in $(
			find "${TESTS_DIR}/../" \
				-mindepth 1 -maxdepth 1 \
				\( -path */.git -or -path */tests \) \
				-prune -o -print
		); do
			cp --archive "${target}" "${sources_template}/sources/" || return $?
		done
	fi
	# then, the one with BME already installed (per-using the sources one)
	local extra_path=$(set_tests_path) || {
			local err_rc=$?
			test_log "(${err_rc})\n${extra_path}" error 0
			return $err_rc
	}
	if ! [ -d "${installed_template}" ]; then
		cp -ra "${sources_template}" "${installed_template}"
		env --ignore-environment \
			PATH="${installed_template}/bin:${extra_path}" \
			SOURCES_DIR="${installed_template}/sources" \
			HOME="${installed_template}" \
			bash -c 'cd ${SOURCES_DIR} && make install'
		rm -rf "${installed_template}/sources"
	fi

# Loops on the tests
	for test in "${tests_list[@]}"; do
		[ -x "${test}" ] || {
			test_log "${T_BOLD}'${test}'${T_NC} is not executable.  Stopping here." error 0
			exit 1
		}

		[ ${DEBUG:+1} ] && echo -e "\tFOUND TEST FILE '${test}'"
		test_log "\n${T_BOLD}$((++test_counter)). '${test}'${T_NC}..." '' 0
		for sub_path in setup core modules; do
			unset test_type
			if [[ ${test#"${TESTS_DIR}/${sub_path}/"} != ${test} ]]; then
				test_type="${sub_path}"
				break
			fi
		done

		local padded_random=$(printf "%03d\n" $((0 + $RANDOM % 999)))
		local test_scratch_dir="${SCRATCH_BASE_DIR}/test_${padded_random}"
		[ ${DEBUG:+1} ] && test_log "TEST's scratch dir: '${test_scratch_dir}'"
		local batch_start=$(date +%s)

		[ ${DEBUG:+1} ] && echo "CURRENT TEST TYPE IS: '${test_type}'"
		case "${test_type}" in
			'setup')
			# just copy the sources to a known path
				[ ${DEBUG:+1} ] && echo "SETUP REQUESTED FOR '${test}'."
			# Copies sources to the test environment
				cp -ra "${sources_template}" "${test_scratch_dir}"
			# runs the test
				env --ignore-environment \
					HOME="${test_scratch_dir}" \
					PATH="${extra_path}" \
					SOURCES_DIR="${test_scratch_dir}/sources" \
					CURRENT_TESTFILE_NUMBER=${test_counter} \
					bash -c "{
						source "${TESTS_DIR}/helper_functions.sh" \
						&& ${test}
					}"
			;;
			'core')
			# BME installed within the environment
				[ ${DEBUG:+1} ] && echo "CORE REQUESTED FOR '${test}'."
			# copies the "pre-computed" template with BME already installed
				cp -ra "${installed_template}" "${test_scratch_dir}"
			# runs the test
				env --ignore-environment \
					PATH="${test_scratch_dir}/bin:${extra_path}" \
					HOME="${test_scratch_dir}" \
					CURRENT_TESTFILE_NUMBER=${test_counter} \
					bash -c "{
						source "${TESTS_DIR}/helper_functions.sh" \
						&& ${test}
					}"
			;;
			'modules')
			# BME installed and active
				[ ${DEBUG:+1} ] && echo "MODULES REQUESTED FOR '${test}'."
			# copies the "pre-computed" template with BME already installed
				cp -ra "${installed_template}" "${test_scratch_dir}"
			# runs the test
				env --ignore-environment \
					PATH="${test_scratch_dir}/bin:${extra_path}" \
					HOME="${test_scratch_dir}" \
					CURRENT_TESTFILE_NUMBER=${test_counter} \
					bash -c "{
						source "${TESTS_DIR}/helper_functions.sh" \
						&& source bash-magic-enviro \
						&& ${test}
					}"
			;;
			*)
				test_log "UNKNOWN: what should I do here?" fatal
				return 1
			;;
		esac

	# Now, check result from command above
		local test_rc=$?
		local batch_duration=$( seconds_duration $(( $(date +%s) - batch_start )) )
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

	echo ''
	local final_msg="${T_BOLD}TEST BATCHES RUN:${T_NC} "
	if (( ${test_rc} == 0 )); then
		local final_status='info'
		rm --recursive --force ${SCRATCH_BASE_DIR}
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

	if [[ "${OSTYPE}" == "darwin"* ]]; then
		if ! which brew > /dev/null; then
			local err_msg="Runing on ${T_BOLD}'${OSTYPE}'${T_NC}:\n"
			err_msg+="\thomebrew is mandatory but couldn't be found."
			test_log "${err_msg}" error 0
			return 1
		fi
	fi
}


# Prepares the restricted environment for tests
function set_tests_path() {
# sets "internal" path
	local tests_path='/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin'

	if [[ "${OSTYPE}" == "darwin"* ]]; then
		local brew_path=$(brew --prefix)
		tests_path="${brew_path}/bin:${tests_path}"

		local gnu_packages=(
			'coreutils'
			'findutils'
			'grep'
			'gnu-sed'
		)
		for gnu_package in ${gnu_packages[@]}; do
			if [[ -d "${brew_path}/opt/${gnu_package}" ]]; then
				tests_path="${brew_path}/opt/${gnu_package}/libexec/gnubin:${tests_path}"
			else
				local warn_msg="WARNING: while trying to set \$PATH for '${gnu_package}':\n"
				warn_msg+="\tdirectory '${brew_path}/opt/${gnu_package}' couldn't be found.\n"
				warn_msg+="\tdid you 'brew install ${gnu_package}'?"
				echo -e "${warn_msg}"
				return 1
			fi
		done
	fi

	echo "${tests_path}"
}

#--
# ENTRY POINT
#--
main "$@"; exit $?
