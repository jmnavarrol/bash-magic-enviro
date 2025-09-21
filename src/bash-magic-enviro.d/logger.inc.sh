# Meant to be sourced from main BME script
# Logging facilities.

# Three maps are required for logging:
# BME_LOG_SEVERITIES: Severities as per standard syslog severities (see https://en.wikipedia.org/wiki/Syslog)
# BME_CUSTOM_LOG_TYPES: Another mapping for "custom log types" to standard severities
# BME_LOG_COLORS: Finally, a map from severities to colors

# "public" functions:
# __bme_log() (callable from bme_log()
# 1st param: 'log_message': the log message itself
# 2st param: 'log_type': log prefix, i.e.: ERROR, WARNING, empty string...
# 3st param: 'log_indent': sets the indentation level of the log output, starting '0'

# "private" functions:
# __logger_clean() Avoids polluting the environment.  Remember adding whatever is need then when developing this include.


# SYSLOG SEVERITIES. See https://en.wikipedia.org/wiki/Syslog
declare -A BME_LOG_SEVERITIES=(
# RED
	['EMERGENCY']=0  # System is unusable - A panic condition
	['ALERT']=1      # Action must be taken immediately - A condition that should be corrected immediately, such as a corrupted system database
	['CRITICAL']=2   # Critical conditions - Hard device errors
	['ERROR']=3      # Error conditions
# YELLOW
	['WARNING']=4    # Warning conditions
	['NOTICE']=5     # Normal but significant conditions - Conditions that are not error conditions, but that may require special handling
# GREEN
	['INFO']=6       # Informational messages - Confirmation that the program is working as expected
# PURPLE
	['DEBUG']=7      # Debug-level messages - Messages that contain information normally of use only when debugging a program
)

# Other custom types mapped to standard syslog ones
declare -A BME_CUSTOM_LOG_TYPES=(
	['EMERGENCY']="${BME_LOG_SEVERITIES['EMERGENCY']}"

	['ALERT']="${BME_LOG_SEVERITIES['ALERT']}"

	['CRITICAL']="${BME_LOG_SEVERITIES['CRITICAL']}"
		['FATAL']="${BME_LOG_SEVERITIES['ERROR']}"

	['ERROR']="${BME_LOG_SEVERITIES['ERROR']}"
		['FAIL']="${BME_LOG_SEVERITIES['ERROR']}"

	['WARNING']="${BME_LOG_SEVERITIES['WARNING']}"

	['NOTICE']="${BME_LOG_SEVERITIES['NOTICE']}"
		['DEPRECATION']="${BME_LOG_SEVERITIES['NOTICE']}"

	['INFO']="${BME_LOG_SEVERITIES['INFO']}"
		['OK']="${BME_LOG_SEVERITIES['INFO']}"
		['LOADING']="${BME_LOG_SEVERITIES['INFO']}"
		['CLEANING']="${BME_LOG_SEVERITIES['INFO']}"
		['FUNCTION']="${BME_LOG_SEVERITIES['INFO']}"

	['DEBUG']="${BME_LOG_SEVERITIES['DEBUG']}"
)

# log types mapping to colors
declare -A BME_LOG_COLORS=(
	["${BME_LOG_SEVERITIES['EMERGENCY']}"]="${C_RED}"
	["${BME_LOG_SEVERITIES['ALERT']}"]="${C_RED}"
	["${BME_LOG_SEVERITIES['CRITICAL']}"]="${C_RED}"
	["${BME_LOG_SEVERITIES['ERROR']}"]="${C_RED}"
	["${BME_LOG_SEVERITIES['WARNING']}"]="${C_YELLOW}"
	["${BME_LOG_SEVERITIES['NOTICE']}"]="${C_YELLOW}"
	["${BME_LOG_SEVERITIES['INFO']}"]="${C_GREEN}"
	["${BME_LOG_SEVERITIES['DEBUG']}"]="${C_PURPLE}"
)

# Logger function
# 1st param: 'log_message': the log message itself
# 2st param: 'log_type': log prefix, i.e.: ERROR, WARNING, empty string...
# 3st param: 'log_indent': sets the indentation level of the log output, starting '0'
__bme_log() {
local log_message="${1}${C_NC}"  # first param (with color reset in case caller forgot it)
local log_type="${2^^}"          # second param (uppercased)
local log_indent=${3:-0}         # third param (with a default of 0)

# Params debug
	__bme_debug "${FUNCNAME[0]}: log_message: ${log_message}"
	__bme_debug "${FUNCNAME[0]}: log_type: ${log_type}"
	__bme_debug "${FUNCNAME[0]}: log_indent: ${log_indent}"

# "pseudo private" function protection
	if [ "${FUNCNAME[1]}" != 'bme_log' ]; then
		local err_msg="${C_RED}INTERNAL ERROR:${C_NC} "
		err_msg+="Function ${C_BOLD}'${FUNCNAME[0]}()'${C_NC} is ${C_BOLD}private${C_NC}.  "
		err_msg+="You shouldn't invoke it from ${C_BOLD}'${FUNCNAME[1]}()${C_NC}!"
		>&2 echo -e "${err_msg}"
		__logger_clean; return 1
	fi

# Checks/Sets BME_LOG_LEVEL to a proper value
	BME_LOG_LEVEL="${BME_LOG_LEVEL^^}"
	if ! [[ " ${!BME_LOG_SEVERITIES[*]} " =~ " ${BME_LOG_LEVEL} " ]]; then
		local err_msg="${C_YELLOW}WARNING:${C_NC} Log level set to a wrong value ${C_BOLD}'${BME_LOG_LEVEL}'${C_NC}.\n"
		BME_LOG_LEVEL="${BME_DEFAULT_LOG_LEVEL}"
		err_msg+="\t${C_BOLD}'BME_LOG_LEVEL'${C_NC} has been reset to default value ${C_BOLD}'${BME_LOG_LEVEL}'${C_NC}."
		>&2 echo -e "${err_msg}"
	fi

# Then, assert the (optional) log type against severity
	if [ -n "${log_type}" ] \
	&& [ -n "${BME_CUSTOM_LOG_TYPES[${log_type}]}" ]; then
		local debug_msg="${FUNCNAME[0]}: '${log_type}' is mapped to severity '${BME_CUSTOM_LOG_TYPES[${log_type}]}'"
		__bme_debug "${debug_msg}"
	# is printable as per requested LOG_LEVEL?
		if (( ${BME_CUSTOM_LOG_TYPES[${log_type}]} > ${BME_LOG_SEVERITIES[${BME_LOG_LEVEL}]} )); then
			local debug_msg="${FUNCNAME[0]}: log message requested at '${log_type}' level.\n"
			debug_msg+="\tbut current log level is '${BME_LOG_LEVEL}'.\n"
			debug_msg+="\tThis message won't be printed:\n"
			debug_msg+="${log_message}"
			__bme_debug "${debug_msg}"
			__logger_clean; return 0
		fi
	else
		local debug_msg="${FUNCNAME[0]}: '${log_type}' is unmapped to a syslog severity: it will always be printed."
		__bme_debug "${debug_msg}"
	fi

# No parameters.  Show help instead
	if (( $# == 0 )); then
		local log_msg="'log message' [log type] [indentation level]\n"
		log_msg+="\n${C_BOLD}bme_log${C_NC} helps you printing formatted output:\n"
		log_msg+="${C_BOLD}1.${C_NC} it will only print messages with higher severity than ${C_BOLD}'BME_LOG_LEVEL'${C_NC} environment variable "
			local severity_index="${BME_LOG_SEVERITIES[${BME_LOG_LEVEL}]}"
			log_msg+="(current value: ${BME_LOG_COLORS[${severity_index}]}${BME_LOG_LEVEL}${C_NC}).\n"
		log_msg+="${C_BOLD}2.${C_NC} it will prefix your messages with a colorized ${C_BOLD}[log type]${C_NC}.\n"
		log_msg+="${C_BOLD}3.${C_NC} it will indent your messages with as many tabs as requested by ${C_BOLD}[indentation level]${C_NC}.\n"
		log_msg+="${C_BOLD}4.${C_NC} if accepts color codes within your log mesages.\n\n"
		log_msg+="${C_BOLD}'log type'${C_NC} will add a colored prefix as shown below:\n"
		log_msg+="\t${C_RED}'EMERGENCY|ALERT|CRITICAL|FATAL|ERROR|FAIL'${C_NC}\n"
		log_msg+="\t${C_YELLOW}'WARNING|NOTICE|DEPRECATION'${C_NC}\n"
		log_msg+="\t${C_GREEN}'INFO|OK|LOADING|CLEANING|FUNCTION'${C_NC}\n"
		log_msg+="\t${C_PURPLE}'DEBUG'${C_NC}\n"
		log_msg+="\t${C_BOLD}'any other log type'${C_NC}\n\n"
		log_msg+="${C_BOLD}Color codes you can use in your messages:${C_NC}\n"
		log_msg+="\t\"\${C_BOLD}${C_BOLD}'BOLD'${C_NC}\${C_NC}\"\n"
		log_msg+="\t\"\${C_GREEN}${C_GREEN}'GREEN'${C_NC}\${C_NC}\"\n"
		log_msg+="\t\"\${C_YELLOW}${C_YELLOW}'YELLOW'${C_NC}\${C_NC}\"\n"
		log_msg+="\t\"\${C_RED}${C_RED}'RED'${C_NC}\${C_NC}\"\n"
		log_msg+="\t\"\${C_PURPLE}${C_PURPLE}'PURPLE'${C_NC}\${C_NC}\""
		bme_log "${log_msg}" ${FUNCNAME[0]}
		__logger_clean; return 0
	fi

# Otherwise, log_message is mandatory
	if [ -z "$log_message" ]; then
		echo -e "${C_RED}FATAL:${C_NC} ${C_BOLD}'${FUNCNAME[0]}'${C_NC} called in code from ${C_BOLD}'${FUNCNAME[1]}'${C_NC} with no message."
		__logger_clean; return $false
	fi

# Adds message type to log message
	if [ -n "${log_type}" ]; then
		local message_header="${log_type}"
		if [ -n "${BME_CUSTOM_LOG_TYPES[${log_type}]}" ]; then
		# if DEBUG, add the calling function name (if any)
			if [ "${log_type}" == 'DEBUG' ] && ((${#FUNCNAME[@]} > 1)); then
				message_header="${message_header} - ${FUNCNAME[1]}()"
			fi
			local mapped_severity="${BME_CUSTOM_LOG_TYPES[${log_type}]}"
			message_header="${BME_LOG_COLORS[${mapped_severity}]}${message_header}:${C_NC}"
		else
			message_header="${C_BOLD}${log_type}:${C_NC}"
		fi
		log_message="${message_header} ${log_message}"
	fi

# Sets indentation level
	local indented_prefix=''
	for (( i=0; i < ${log_indent}; i++ )); do
		indented_prefix+='\t'
	done
	unset i

	# transforms input message into an array so it can be processed line by line
	readarray -t log_message <<< $(echo -e "${log_message}")

	# adds the requested indentation to the output
	for line in "${log_message[@]}"; do
		echo -e "${indented_prefix}${line}"
	done
	unset line

# Clean after myself
	__logger_clean
}


# Cleans whatever is loaded on this file
__logger_clean() {

	unset BME_LOG_SEVERITIES
	unset BME_CUSTOM_LOG_TYPES
	unset BME_LOG_COLORS

	unset -f __bme_log
	unset -f __logger_clean
}
