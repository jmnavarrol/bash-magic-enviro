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
	test_title "Load virtualenvwrapper at '${VIRTUALENVWRAPPER_SCRIPT}':"
	source "${VIRTUALENVWRAPPER_SCRIPT}" || {
		local_rc=$?
		err_msg="${C_BOLD}'${VIRTUALENVWRAPPER_SCRIPT}'${C_NC} wasn't found.\n"
		err_msg+="\tMake sure you installed ${C_BOLD}'virtualenvwrapper'${C_NC} and this script points to the proper path."
		test_log "${err_msg}" error
		return $local_rc
	}
	test_log "${T_GREEN}OK${T_NC}"

# Sets a project environment
	test_title "sets a project environment"
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
	file_contents=`cat "${bme_project_dir}/.bme_project"`
	test_log "${T_BOLD}---> PROJECT FILE START${T_NC}"
	test_log "${file_contents}"
	test_log "${T_BOLD}<--- PROJECT FILE END${T_NC}"

# whitelists the project
	mkdir --parents "${HOME}/.bme.d" || return $?
	cat <<- EOF > "${HOME}/.bme.d/whitelistedpaths"
	declare -gA BME_WHITELISTED_PATHS=(
		[${bme_project_dir}]=true
	)
	EOF
	file_contents=`cat "${HOME}/.bme.d/whitelistedpaths"`
	test_log "${T_BOLD}---> WHITELIST FILE START${T_NC}"
	test_log "${file_contents}"
	test_log "${T_BOLD}<--- WHITELIST FILE END${T_NC}"

# reloads configuration
	source bash-magic-enviro || return $?
	test_log "${T_GREEN}OK${T_NC}"

# tests
	call_virtualenv_without_param || return $?
	create_empty_virtualenv || return $?
	create_virtualenv_with_extra_param || return $?
}


#--
# HELPER FUNCTIONS
#--
function call_virtualenv_without_param() {
	source bash-magic-enviro || exit $?

	test_title "call 'load_virtualenv' without parameters"
	cd "${bme_project_dir}" && bme_eval_dir || return $?
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
	test_title "create an empty virtualenv"
	cd "${bme_project_dir}" && bme_eval_dir || return $?
	function_output=$(load_virtualenv 'test-virtualenv' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		test_log "Check ${C_BOLD}'empty virtualenv creation'${C_NC}:" error
		test_log "${T_BOLD}---> OUTPUT START${T_NC}"
		test_log "${function_output}" '' 2
		test_log "${T_BOLD}<--- OUTPUT END${T_NC}"
		return $rc
	fi
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
	rmvirtualenv 'test-virtualenv' || exit $?
	test_log "${C_GREEN}OK${C_NC}"
}


function create_virtualenv_with_extra_param() {
	test_title "create virtualenv with extra param for requirements:"
	mkdir --parents "${bme_project_dir}/requirements_subdir"
	echo -e 'hello-hello' > "${bme_project_dir}/requirements_subdir/requirements.txt"

	cd "${bme_project_dir}" && bme_eval_dir || return $?

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
	echo -e 'wheel' >> "${bme_project_dir}/requirements_subdir/requirements.txt"
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


main; exit $?
