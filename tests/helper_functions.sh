# Helper functions that can be used by unit tests
# Meant to be sourced from main maketests.sh script.

# Tests' Style table
export T_BOLD='\033[1m'         # Bold text
export T_GREEN='\033[1;32m'     # Green (and bold)
export T_YELLOW='\033[1;1;33m'  # Yellow (and bold)
export T_RED='\033[1;31m'       # Red (and bold)
export T_NC='\033[0m'           # No Color

# Helps showing current test title and order
# 1st param: 'test_title': the (uppercased) test title.
function test_title() {
local test_title="${1^^}"

	local title_msg="${T_BOLD}${CURRENT_TESTFILE_NUMBER}.$((++subtest_counter))"
	title_msg+=" ${FUNCNAME[1]}():"
	title_msg+=" ${test_title}${T_NC}"
	echo -e "${title_msg}"
}
export -f test_title


# Helper to show test logs
# (quite similar to BME's bme_log() function)
# 1st param: 'log_message': it will be indented once by default.
# 2st param: 'log_type': log prefix, i.e.: ERROR, WARNING, empty string...
# 3st param: 'log_level': sets the indentation level of the log output, defaults to '1'
function test_log() {
local log_msg="${1}"
local log_type="${2^^}"   # second param (uppercased)
local log_level=${3:-1}   # indentation level (with a default of 1)

# Adds log type prefix
	case "$log_type" in
		FATAL | ERROR | FAIL)
			log_msg="${T_RED}${log_type}:${T_NC} ${log_msg}"
		;;
		WARNING)
			log_msg="${T_YELLOW}${log_type}:${T_NC} ${log_msg}"
		;;
		INFO | OK \
		| LOADING | CLEANING \
		| FUNCTION)
			log_msg="${T_GREEN}${log_type}:${T_NC} ${log_msg}"
		;;
		*)
			if [ -n "$log_type" ]; then
				log_msg="${T_BOLD}${log_type}:${T_NC} ${log_msg}"
			fi
		;;
	esac

# Let's convert the (possibly) multiline message into a "proper" array
	readarray -t log_msg <<< $(echo -e "${log_msg}")

# Set the log indentation level
	local indented_prefix=''
	for ((i=0; i<${log_level}; i++)); do
		indented_prefix+="\t"
	done

# Pad each line
	for line in "${log_msg[@]}"; do
		echo -e "${indented_prefix}${line}"
	done
	unset line
}
export -f test_log


# Strips ANSI escape codes/sequences so tests can assert return messages with ease.
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
	unset line

	echo -en "${stripped_output}"
}
export -f strip_escape_codes

