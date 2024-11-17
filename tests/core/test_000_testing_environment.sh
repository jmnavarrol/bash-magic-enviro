#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests the testing framework itself

function main() {
	test_title "Assert that 'bash-magic-enviro' can be sourced without error:"
	test_log "PATH IS: ${T_BOLD}'${PATH}'${T_NC}"
	test_log "HOME IS: ${T_BOLD}'${HOME}'${T_NC}"
# Test loading main BME function
	bme_output=`source bash-magic-enviro` || {
		local bme_rc=$?
		local err_msg="(${bme_rc}) Couldn't source ${T_BOLD}'bash-magic-enviro'${T_NC}."
		err_msg+="\n\tPlease make sure ${T_BOLD}'bash-magic-enviro'${T_NC} is installed and in your path!\n"
		err_msg+=$(test_log "\n${bme_output}")
		test_log "${err_msg}" error
		return ${bme_rc}
	}

	test_log "${T_GREEN}OK${T_NC}"
}

main; exit $?
