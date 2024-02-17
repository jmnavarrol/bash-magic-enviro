#!/usr/bin/env bash
shopt -s nullglob

readonly TESTS_DIR=$(dirname $(realpath "${BASH_SOURCE[0]}"))
readonly SCRIPT="${SCRIPT:-bash-magic-enviro}"
readonly BUILD_DIR="${BUILD_DIR:-${TESTS_DIR}/../build}"
readonly MODULES_DIR="${MODULES_DIR:-${BUILD_DIR}/${SCRIPT}_modules}"

# Style table
export C_BOLD='\033[1m'         # Bold text
export C_GREEN='\033[1;32m'     # Green (and bold)
export C_YELLOW='\033[1;1;33m'  # Yellow (and bold)
export C_RED='\033[1;31m'       # Red (and bold)
export C_NC='\033[0m'           # No Color

#--
# HELPER FUNCTIONS
#--
# Logger function
# 1st param: 'log_message': the log message itself
# 2st param: 'log_type': log prefix, i.e.: ERROR, WARNING, empty string...
# 3st param: 'log_level': sets the indentation level of the log output, starting '0'
btest_log() {
local log_message="${1}"  # first param
local log_type="${2^^}"   # second param (uppercased)
local log_level=${3:-0}   # third param (with a default of 0)
local full_message=''
# Params debug
# 	echo "log_message: ${log_message}"
# 	echo "log_type: ${log_type}"
# 	echo "log_level: ${log_level}"

	# No parameters.  Show help instead
	if (( $# == 0 )); then
		local log_msg="'log message' ['log type' (see below)] [indentation level (0,1,2...)]"
		log_msg+="\n${C_BOLD}'log type'${C_NC} will add a colored prefix as shown below:"
		log_msg+="\n\t${C_GREEN}'INFO|OK|LOADING|CLEANING|FUNCTION'${C_NC}"
		log_msg+="\n\t${C_YELLOW}'WARNING'${C_NC}"
		log_msg+="\n\t${C_RED}'FATAL|ERROR|FAIL'${C_NC}"
		log_msg+="\n\t${C_BOLD}'any other log type'${C_NC}"
		log_msg+="\n${C_BOLD}Color codes you can use in your messages:${C_NC}"
		log_msg+="\n\t\"\${C_BOLD}${C_BOLD}'BOLD'${C_NC}\${C_NC}\""
		log_msg+="\n\t\"\${C_GREEN}${C_GREEN}'GREEN'${C_NC}\${C_NC}\""
		log_msg+="\n\t\"\${C_YELLOW}${C_YELLOW}'YELLOW'${C_NC}\${C_NC}\""
		log_msg+="\n\t\"\${C_RED}${C_RED}'RED'${C_NC}\${C_NC}\""
		bme_log "${log_msg}" ${FUNCNAME[0]}
		return 0
	fi

	# standard log message processing
	if [ -z "$log_message" ]; then
		echo -e "${C_RED}FATAL:${C_NC} ${C_BOLD}'${FUNCNAME[0]}'${C_NC} called in code from ${C_BOLD}'${FUNCNAME[1]}'${C_NC} with no message."
		return -1
	fi
# Sets indentation level
	local indent_size=''
	for (( i=0; i < ${log_level}; i++ )); do
		indent_size+='\t'
# 		full_message+='\t'
	done
	unset i
	full_message="${indent_size}"
# Then, message type
	case "$log_type" in
		FATAL | ERROR | FAIL)
			full_message+="${C_RED}${log_type}:${C_NC} "
		;;
		WARNING)
			full_message+="${C_YELLOW}${log_type}:${C_NC} "
		;;
		INFO | OK \
		| LOADING | CLEANING \
		| FUNCTION)
			full_message+="${C_GREEN}${log_type}:${C_NC} "
		;;
		*)
			if [ -n "$log_type" ]; then
				full_message+="${C_BOLD}${log_type}:${C_NC} "
			fi
		;;
	esac
# Finally, the message itself
	# this will turn the message into a list of lines
	mapfile -t log_message <<< `echo -e "${log_message}"`
	# The first line goes 'as-is' after the log_type (which already is on the final string)
	full_message+="${log_message[0]}\n"
	# All the other lines should be indented by log_level
	for line in "${log_message[@]:1}"; do
		full_message+="${indent_size}${line}\n"
	done
	unset line

	echo -en "${full_message}"
	unset full_message
}
export -f btest_log


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
# Checking environment
err_msg="${C_BOLD}While checking environment...${C_NC}\n"
[ -d "${BUILD_DIR}" ] || {
	err_msg+="\tNo build dir ${C_BOLD}'${BUILD_DIR}'${C_NC} found!\n"
	err_msg+="\tDid you forget running ${C_BOLD}'make build'${C_NC}?"
	btest_log "${err_msg}" error
	exit 1
}

[ -d "${BUILD_DIR}/${SCRIPT}_modules" ] || {
	err_msg+="\tNo build dir ${C_BOLD}'${BUILD_DIR}/${SCRIPT}_modules'${C_NC} found!\n"
	err_msg+="\tDid you forget running ${C_BOLD}'make build'${C_NC}?"
	btest_log "${err_msg}" error
	exit 1
}

[ -n "${VERSION}" ] || {
	err_msg+="\t'VERSION' environment variable not found!\n"
	err_msg+="\tDid you forget running ${C_BOLD}'make build'${C_NC}?"
	btest_log "${err_msg}" error
	exit 1
}

btest_log "${C_BOLD}BUILD DIR:${C_NC} '${BUILD_DIR}'" && export BUILD_DIR
btest_log "${C_BOLD}MODULES DIR:${C_NC} '${MODULES_DIR}'" && export MODULES_DIR
btest_log "${C_BOLD}CURRENT VERSION IS:${C_NC} '${VERSION}'" && export VERSION
btest_log "${C_BOLD}RUNNING TESTS ON:${C_NC} '${TESTS_DIR}/'\n" && export TESTS_DIR

# Run tests
cd "${TESTS_DIR}"
export SCRATCH_DIR="${TESTS_DIR}/scratch"
rm --recursive --force "${SCRATCH_DIR}"

for test in test_*.sh; do
	btest_log "running ${C_BOLD}'${test}'${C_NC}" info
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
btest_log "${C_BOLD}Unitary tests:${C_NC} ${C_GREEN}OK${C_NC}"
