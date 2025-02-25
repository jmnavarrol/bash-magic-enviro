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
local log_msg="${1}"     # log message
local log_type="${2^^}"  # log type (uppercased)
local log_level=${3:-1}  # indentation level (with a default of 1)

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

	local final_msg=$(indentor "${log_msg}" ${log_level})
	echo -e "${final_msg}"
}
export -f test_log

# Indents each line a number of tabs
# 1st param: the text to indent
# 2nd param: the number of tabs to indent
function indentor {
local original_text="${1}"
local indentation=${2}

	local indented_prefix=''
	for ((i=0; i<${indentation}; i++)); do
		indented_prefix+="\t"
	done

# Let's convert the (possibly) multiline message into a "proper" array
	readarray -t original_text <<< $(echo -e "${original_text}")

	for line in "${original_text[@]}"; do
		echo -e "${indented_prefix}${line}"
	done
}
export -f indentor


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


# Converts seconds to properly formatted time
# 1st param: the number of seconds to convert
function seconds_duration() {
local seconds="${1}"

	if [ -z "${seconds}" ]; then
		test_log "You should call 'seconds_duration' with a seconds parameter." fatal
		return 1
	fi

	local hours=$((${seconds}/3600))
	local minutes=$(((${seconds}/60)%60))
	local seconds=$((${seconds}%60))
	printf "%02d:%02d:%02d" ${hours} ${minutes} ${seconds}
}
