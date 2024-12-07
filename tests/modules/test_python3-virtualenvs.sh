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
	call_virtualenv_without_param || return $?
	create_empty_virtualenv || return $?
	create_virtualenv_with_extra_param || return $?
	create_virtualenv_with_custom_pip || return $?
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


function call_virtualenv_without_param() {
	source bash-magic-enviro || return $?

	test_title "call 'load_virtualenv' without parameters"
	cd "${project_dir}" && bme_eval_dir || return $?
	function_output=$(load_virtualenv 2>&1)
	stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"mandatory param 'venv_name' not set".* ]]; then
		test_log "Check ${C_BOLD}'virtualenv without param'${C_NC}: ${C_GREEN}OK${C_NC}" info
	else
		local rc=$?
		local err_msg="Check ${C_BOLD}'virtualenv without param'${C_NC}:"
		err_msg+="\n${T_BOLD}---> OUTPUT START${T_NC}"
		test_log "${err_msg}" error
		test_log "${function_output}" '' 2
		test_log "${T_BOLD}<--- OUTPUT END${T_NC}"
		return $rc
	fi
	test_log "${T_GREEN}OK${T_NC}"
}


function create_empty_virtualenv() {
	source bash-magic-enviro || return $?

	test_title "create an empty virtualenv"
	cd "${project_dir}" && bme_eval_dir || return $?
	function_output=$(load_virtualenv 'test-virtualenv' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		test_log "Check ${C_BOLD}'empty virtualenv creation'${C_NC}:" error
		test_log "${T_BOLD}---> OUTPUT START${T_NC}"
		test_log "${function_output}" '' 2
		test_log "${T_BOLD}<--- OUTPUT END${T_NC}"
		return $rc
	fi
	echo "${function_output}"
	unset function_output

# Checks the results
	for file in \
		"${BME_PROJECT_CONFIG_DIR}/python-virtualenvs.lockfile" \
		"${BME_PROJECT_CONFIG_DIR}/python-virtualenvs.md5"
	do
		if ! [ -r "${file}" ]; then
			err_msg="Check ${C_BOLD}'empty virtualenv creation'${C_NC}:\n"
			err_msg+="\tExpected file ${C_BOLD}'${file}'${C_NC} not found."
			test_log "${err_msg}" fail
			return 1
		fi
	done
# 	rmvirtualenv 'test-virtualenv' || exit $?
	test_log "${C_GREEN}OK${C_NC}"
}


function create_virtualenv_with_extra_param() {
	source bash-magic-enviro || return $?

	test_title "create virtualenv with extra param for requirements:"
	mkdir --parents "${project_dir}/requirements_subdir" || return $?
	echo -e 'hello-hello' > "${project_dir}/requirements_subdir/requirements.txt" || return $?

	cd "${project_dir}" && bme_eval_dir || return $?

# Load a virtualenv with parameter
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		test_log "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}:" fail
		test_log "${C_BOLD}---> OUTPUT START${C_NC}"
		test_log "${function_output}" '' 1
		test_log "${C_BOLD}<--- OUTPUT END${C_NC}"
		return $rc
	fi
	unset function_output
	bme_log "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}." ok

# Load it again without changes
	test_title "parameterized virtualenv reload"
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		test_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}:" fail
		test_log "${C_BOLD}---> OUTPUT START${C_NC}"
		test_log "${function_output}" '' 1
		test_log "${C_BOLD}<--- OUTPUT END${C_NC}"
		return $rc
	else
		test_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}." ok
	fi

# Load once again, this time with a change
	test_title "load it again, with an update"
	echo -e 'wheel' >> "${project_dir}/requirements_subdir/requirements.txt"
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		test_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}:" fail
		test_log "${C_BOLD}---> OUTPUT START${C_NC}"
		test_log "${function_output}" '' 1
		test_log "${C_BOLD}<--- OUTPUT END${C_NC}"
		return $rc
	else
		test_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}." ok
	fi

# Clean
	cd "${HOME}" && bme_eval_dir || return $?
	test_log "virtualenv with parameter management" ok
}


function create_virtualenv_with_custom_pip() {
	source bash-magic-enviro || return $?

	test_title "create virtualenv with custom pip version:"

# Creates a suitable requirements file
	mkdir --parents "${project_dir}/python-virtualenvs" || return $?
	cat <<- EOF > "${project_dir}/python-virtualenvs/with-pip.requirements"
	example-package-name-mc==0.0.1
	pip==21.0.1
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		test_log "WHILE CREATING REQUIREMENTS FILE AT ${T_BOLD}'${project_dir}/python-virtualenvs/with-pip.requirements'${T_NC}." error
		[ -r "${project_dir}/python-virtualenvs/with-pip.requirements" ] && {
			file_contents=`cat "${project_dir}/python-virtualenvs/with-pip.requirements"`
			test_log "${T_BOLD}---> REQUIREMENTS FILE START${T_NC}"
			test_log "${file_contents}" '' 2
			test_log "${T_BOLD}<--- REQUIREMENTS FILE END${T_NC}"
			unset file_contents
		}
		return $rc_code
	fi
# And then, a suitable .bme_env file
	cat <<- 'EOF' > "${project_dir}/.bme_env"
	load_virtualenv 'with-pip' || return $?
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		test_log "WHILE CREATING .bme_env FILE AT ${T_BOLD}'${project_dir}/.bme_env'${T_NC}." error
		[ -r "${project_dir}/.bme_env" ] && {
			file_contents=`cat "${project_dir}/.bme_env"`
			test_log "${T_BOLD}---> BME_ENV FILE START${T_NC}"
			test_log "${file_contents}" '' 2
			test_log "${T_BOLD}<--- BME_ENV FILE END${T_NC}"
			unset file_contents
		}
		return $rc_code
	fi

# Load the environment and check the results
	cd "${project_dir}" && bme_eval_dir || return $?
	pip freeze --all | grep --quiet 'pip==21.0.1' || {
		test_log "virtualenv with custom pip (see above)" fail
		pip freeze --all
		return 1
	}

	test_log "virtualenv with custom pip" ok
}

main; exit $?
