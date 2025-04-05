#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# See https://en.wikipedia.org/wiki/Syslog
valid_log_severities=(
	'emergency'
	'alert'
	'critical'
	'error'
	'warning'
	'notice'
	'info'
	'debug'
)

# Tests BME_LOG features
function main() {
	source bash-magic-enviro || exit $?
	check_log_indentation || exit $?
	check_log_level_set || exit $?
	check_log_level_valid || exit $?
}


# Ensures log indentation is preserved
function check_log_indentation() {
	test_title ''

# a random integer with a range of 3 starting at 1 (so integers in the 1-3 range)
	local indentation=$((
		(RANDOM % 3) + 1
	))
	local indented_prefix=''
	for ((i=0; i<${indentation}; i++)); do
		indented_prefix+="\t"
	done
	unset i

# the message to be logged in array form
	local message_array=(
		"${C_BOLD}HELLO, WORLD!${C_NC}\n"
		"\teach line of this message should be indented ${C_BOLD}'${indentation}'${C_NC} times to the right."
	)
# ...and in single string form
	local msg_string=''
	local expected_msg_string=''
	local i=0
	while (( $i < ${#message_array[@]} )); do
		msg_string+="${message_array[$i]}"
		expected_msg_string+="${indented_prefix}${message_array[$i]}"
		((i++))
	done
	# expand control codes in the expected string
	expected_msg_string=$(echo -e "${expected_msg_string}")

# Process the log string
	local output_msg=$(bme_log "${msg_string}" '' ${indentation})
	if [[ "${output_msg}" != "${expected_msg_string}" ]]; then
		local err_msg="WHILE TESTING A MULTILINE INDENTED LOG MESSAGE:\n"
		err_msg+="Requested relative indentation: ${T_BOLD}'${indentation}'${T_NC} (${T_BOLD}'${indented_prefix}'${T_NC}):\n"
		err_msg+="${T_BOLD}It should be:${T_NC}\n"
		err_msg+="|---> LOG MESSAGE START\n"
		err_msg+="${expected_msg_string}"
		err_msg+="\n|<--- LOG MESSAGE END\n"
		err_msg+="${T_BOLD}I got:${T_NC}\n"
		err_msg+="|---> LOG MESSAGE START\n"
		err_msg+="${output_msg}"
		err_msg+="\n|<--- LOG MESSAGE END"
		test_log "${err_msg}" fail
		return 1
	else
		test_log "Check ${T_BOLD}'bme_log indentation'${T_NC}" ok
	fi
}


# Ensures BME_LOG_LEVEL is set
function check_log_level_set() {
local default_log_level='INFO'

	test_title "'BME_LOG_LEVEL' is set to its default '${default_log_level}' level"

	if [ -z "${BME_LOG_LEVEL}" ]; then
		test_log "${T_BOLD}'BME_LOG_LEVEL'${T_NC} environment variable should be set." fail
		return 1
	elif [ "${BME_LOG_LEVEL}" != "${default_log_level}" ]; then
		local log_msg="${T_BOLD}'BME_LOG_LEVEL'${T_NC} set to wrong value:\n"
		log_msg+="\texpected value: ${T_BOLD}'${default_log_level}'${T_NC}.\n"
		log_msg+="\tgot: ${T_BOLD}'${BME_LOG_LEVEL}'${T_NC}."
		test_log "${log_msg}" fail
		return 1
	fi

	test_log "Check ${T_BOLD}'log level set'${T_NC}" ok
}


# Ensures BME_LOG_LEVEL gets a valid value
function check_log_level_valid() {
	test_title "'BME_LOG_LEVEL' is set a valid severity level"

	for severity in "${valid_log_severities[@]}"; do
		BME_LOG_LEVEL="${severity}"
		# re-sources BME to set the new log severity
		source bash-magic-enviro || exit $?
		if [[ "${severity^^}" != "${BME_LOG_LEVEL}" ]]; then
			local err_msg="Unexpected log level.\n"
			err_msg+="\texpected: ${T_GREEN}'${severity^^}'${T_NC};"
			err_msg+=" got ${T_RED}'${BME_LOG_LEVEL}'${T_NC} instead"
			test_log "${err_msg}" fail
			return 1
		fi
	done
	unset severity
	test_log "Check ${T_BOLD}'valid log severities'${T_NC}" ok

	test_title "'BME_LOG_LEVEL' is set to an invalid value"

	BME_LOG_LEVEL='foo'
	# re-sources BME to set the new log severity
	source bash-magic-enviro || exit $?
	# log level should be re-set to default 'INFO' level
	if [ "${BME_LOG_LEVEL}" != 'INFO' ]; then
		local err_msg="Unexpected log level.\n"
		err_msg+="\texpected: ${T_GREEN}'INFO'${T_NC};"
		err_msg+=" got ${T_RED}'${BME_LOG_LEVEL}'${T_NC} instead"
		test_log "${err_msg}" fail
		return 1
	fi
	unset BME_LOG_LEVEL
	test_log "Check ${T_BOLD}'invalid log severity'${T_NC}" ok
}


main; exit $?
