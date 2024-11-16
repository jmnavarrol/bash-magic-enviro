#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables

# Tests the python3-virtualenvs module

# WARNING: For these tests you should make sure you have virtualenvwrapper script installed and its path.
readonly VIRTUALENVWRAPPER_SCRIPT='/usr/share/virtualenvwrapper/virtualenvwrapper.sh'


#--
# MAIN
#--
function main() {
# Loads virtualenvwrapper
	source bash-magic-enviro || exit $?
	source "${VIRTUALENVWRAPPER_SCRIPT}" || {
		local_rc=$?
		err_msg="${C_BOLD}'${VIRTUALENVWRAPPER_SCRIPT}'${C_NC} wasn't found.\n"
		err_msg+="\tMake sure you installed ${C_BOLD}'virtualenvwrapper'${C_NC} and this script points to the proper path."
		bme_log "${err_msg}" error
		exit $local_rc
	}
# Sets a project environment
	bme_project_dir="${HOME}/project"
	mkdir --parents "${bme_project_dir}" || return $?

	# ...with a suitable project file
	cat <<- EOF > "${bme_project_dir}/.bme_project"
	# This is a test BME project
	BME_PROJECT_NAME='project'
	BME_MODULES=(
		python3-virtualenvs
	)
	EOF
	echo "---> BME PROJECT FILE:"
	cat "${bme_project_dir}/.bme_project"
	echo "<--- END OF BME PROJECT FILE"

# whitelists the project
	cat <<- EOF > ${BME_WHITELISTED_FILE}
	declare -gA BME_WHITELISTED_PATHS=(
		[${bme_project_dir}]=true
	)
	EOF
	echo "---> WHITELIST FILE:"
	cat "${BME_WHITELISTED_FILE}"
	echo "<--- END OF WHITELIST FILE"

# reloads configuration
	source bash-magic-enviro || return $?

# tests
	call_virtualenv_without_param || return $?
	create_empty_virtualenv || return $?
	create_virtualenv_with_extra_param || return $?
}


#--
# HELPER FUNCTIONS
#--
function call_virtualenv_without_param() {
	cd "${bme_project_dir}" && bme_eval_dir || return $?
	function_output=$(load_virtualenv 2>&1)
	stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"mandatory param 'venv_name' not set".* ]]; then
		bme_log "Check ${C_BOLD}'virtualenv without param'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
	else
		bme_log "Check ${C_BOLD}'virtualenv without param'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		return $rc
	fi
}


function create_empty_virtualenv() {
# Creates an 'empty' virtualenv
	cd "${bme_project_dir}" && bme_eval_dir || return $?
	function_output=$(load_virtualenv 'test-virtualenv' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		bme_log "Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		return $rc
	fi
	unset function_output
# Checks the results
	for file in \
		"${BME_PROJECT_CONFIG_DIR}/python-virtualenvs.lockfile" \
		"${BME_PROJECT_CONFIG_DIR}/python-virtualenvs.md5"
	do
		if ! [ -r "${file}" ]; then
			err_msg="Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}\n"
			err_msg+="\tExpected file ${C_BOLD}'${file}'${C_NC} not found."
			bme_log "${err_msg}"
			return 1
		fi
	done
	rmvirtualenv 'test-virtualenv' || exit $?
	bme_log "Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
}


function create_virtualenv_with_extra_param() {
	mkdir --parents "${bme_project_dir}/requirements_subdir"
	echo -e 'hello-hello' > "${bme_project_dir}/requirements_subdir/requirements.txt"

	cd "${bme_project_dir}" && bme_eval_dir || return $?

# Load a virtualenv with parameter
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		bme_log "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		return $rc
	fi
	unset function_output
	bme_log "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}: ${C_GREEN}OK${C_NC}" info 1

# Load it again without changes
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		bme_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		return $rc
	else
		bme_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
	fi

# Load once again, this time with a change
	echo -e 'wheel' >> "${bme_project_dir}/requirements_subdir/requirements.txt"
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		bme_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		return $rc
	else
		bme_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
	fi

# Clean
	cd "${HOME}" && bme_eval_dir || return $?
}


main; exit $?
