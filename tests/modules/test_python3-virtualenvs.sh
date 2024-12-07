#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables

# Tests the module's load/unload process

#--
# MAIN
#--
main() {
# environment properties
	export project_dir="${HOME}/python3-virtualenvs"
	mkdir --parents "${project_dir}" || return $?

# tests
	create_project_config || return $?
	load_module || return $?
}


#--
# HELPER FUNCTIONS
#--
create_project_config() {
# loads BME so its variables are available
	source bash-magic-enviro > /dev/null || return $?

# Creates a suitable project file
	cat <<- EOF > "${project_dir}/${BME_PROJECT_FILE}"
	# This is a test BME project to test the python3-virtualenvs module
	BME_PROJECT_NAME='python3_virtualenvs'
	BME_MODULES=(
		python3-virtualenvs
	)
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		test_log "WHILE CREATING BME's PROJECT FILE AT ${T_BOLD}'${project_dir}/${BME_PROJECT_FILE}'${T_NC}." error
		[ -r "${project_dir}/${BME_PROJECT_FILE}" ] && {
			file_contents=`cat "${project_dir}/${BME_PROJECT_FILE}"`
			test_log "${T_BOLD}---> BME PROJECT FILE START${T_NC}"
			test_log "${file_contents}" '' 2
			test_log "${T_BOLD}<--- BME PROJECT FILE END${T_NC}"
			unset file_contents
		}
		return $rc_code
	fi

# whitelists the project
	mkdir --parents "${BME_CONFIG_DIR}"
	cat <<- EOF > "${BME_WHITELISTED_FILE}"
	declare -gA BME_WHITELISTED_PATHS=(
		[${project_dir}]=true
	)
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		test_log "WHILE CREATING BME's WHITELIST FILE AT ${T_BOLD}'${BME_WHITELISTED_FILE}'${T_NC}." error
		[ -r "${BME_WHITELISTED_FILE}" ] && {
			file_contents=`cat "${BME_WHITELISTED_FILE}"`
			test_log "${T_BOLD}---> WHITELIST FILE START${T_NC}"
			test_log "${file_contents}" '' 2
			test_log "${T_BOLD}<--- WHITELIST FILE END${T_NC}"
			unset file_contents
		}
		return $rc_code
	fi

# finally, reload BME so whitelisting is updated
	source bash-magic-enviro || return $?
}


load_module() {
	test_title "python3-virtualenvs module clean load/unload"

	local regex_var='^(PWD|OLDPWD|MYOLDPWD|BASH_REMATCH|i|_)='

# activates the project
	declare | grep -vE "${regex_var}" > "${HOME}/before.txt"
	in_output=$(cd "${project_dir}" 2>&1 && bme_eval_dir 2>&1) || in_rc=$?
	${in_rc} || {
		test_log "(${in_rc}) while loading project config at ${T_BOLD}'${project_dir}'${T_NC}" error
		test_log "${T_BOLD}OUTPUT >>>${T_NC}"
		test_log "${in_output}" '' 2
		test_log "${T_BOLD}<<< END OF OUTPUT${T_NC}"
		return ${in_rc}
	}
	unset in_output

# deactivates the project
	out_output=$(cd "${HOME}" 2>&1 && bme_eval_dir 2>&1) || out_rc=$?
	${out_rc} || {
		test_log "(${out_rc}) while unloading project config at ${T_BOLD}'${project_dir}'${T_NC}" error
		test_log "${T_BOLD}OUTPUT >>>${T_NC}"
		test_log "${in_output}" '' 2
		test_log "${T_BOLD}<<< END OF OUTPUT${T_NC}"
		return ${out_rc}
	}
	unset out_output
	declare | grep --invert-match --extended-regexp "${regex_var}" > "${HOME}/after.txt"

# there should be no diff between before and after
	diff "${HOME}/before.txt" "${HOME}/after.txt" || {
		test_log "loading/unloading a BME project polutes environment (see above)" error
		return 1
	}
	rm --force "${HOME}/before.txt" "${HOME}/after.txt"

	unset in_output out_output

	test_log "${T_GREEN}OK${T_NC}"
}

main; exit $?
