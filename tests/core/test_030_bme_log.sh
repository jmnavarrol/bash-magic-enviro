#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Log severities
# See https://en.wikipedia.org/wiki/Syslog
	declare -A log_severities=(
		['error']=3
		['warning']=4
		['info']=6
		['debug']=7
	)

# Tests BME_LOG features
function main() {
	source bash-magic-enviro || exit $?
	check_log_severity || exit $?
# 	check_log_indentation || exit $?
}


#--
# CHECKS LOG LEVEL THRESOLDS
#--
check_log_severity() {

# this should always be printed
	test_title 'non-severity message should always be printed'

	local non_severity='non-severity'
	local expected_output=$(echo -e "${C_BOLD}${non_severity^^}:${C_NC} test message.")

	for severity in "${!log_severities[@]}"; do
		BME_LOG_LEVEL="${severity}"
		local log_output=$(bme_log "test message." "${non_severity}")

		if [ "${log_output}" != "${expected_output}" ]; then
			local err_msg="\n${T_BOLD}EXPECTED OUTPUT:${T_NC}\n"
			err_msg+=$(indentor "'${expected_output}'" 1)
			err_msg+="\n${T_BOLD}GOT:${T_NC}\n"
			err_msg+=$(indentor "'${log_output}'" 1)
			test_log "${err_msg}" fail
			return 1
		fi
	done
	unset severity
	test_log "${T_GREEN}OK${T_NC}"
}


#--
# EVALUATES INDENTATION IS PRESERVED
#--
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
		test_log "Check ${C_BOLD}'bme_log indentation'${C_NC}: ${C_GREEN}OK${C_NC}" info
	fi
}

main; exit $?
