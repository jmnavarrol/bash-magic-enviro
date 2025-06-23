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
	create_virtualenv_with_includes || return $?
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
		local err_msg="WHILE CREATING BME's PROJECT FILE AT ${T_BOLD}'${project_dir}/${BME_PROJECT_FILE}'${T_NC}."
		[ -r "${project_dir}/${BME_PROJECT_FILE}" ] && {
			file_contents=$(<"${project_dir}/${BME_PROJECT_FILE}")
			err_msg+="\n${T_BOLD}---> BME PROJECT FILE START${T_NC}\n"
			err_msg+=$(indentor "${file_contents}" 1)
			err_msg+="${T_BOLD}\n<--- BME PROJECT FILE END${T_NC}"
			test_log "${err_msg}" error
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
		local err_msg="WHILE CREATING BME's WHITELIST FILE AT ${T_BOLD}'${BME_WHITELISTED_FILE}'${T_NC}."
		[ -r "${project_dir}/${BME_PROJECT_FILE}" ] && {
			file_contents=$(<"${project_dir}/${BME_PROJECT_FILE}")
			err_msg+="\n${T_BOLD}---> WHITELIST FILE START${T_NC}\n"
			err_msg+=$(indentor "${file_contents}" 1)
			err_msg+="${T_BOLD}\n<--- WHITELIST FILE END${T_NC}"
			test_log "${err_msg}" error
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
	in_output=$(
		source bash-magic-enviro || return $?
		cd "${project_dir}" 2>&1 && bme_eval_dir 2>&1
	) || in_rc=$?
	${in_rc} || {
		local err_msg="(${in_rc}) while loading project config at ${T_BOLD}'${project_dir}'${T_NC}\n"
		err_msg+="${T_BOLD}OUTPUT >>>${T_NC}\n"
		err_msg+=$(indentor "${in_output}" 1)
		err_msg+="\n${T_BOLD}<<< END OF OUTPUT${T_NC}"
		test_log "${err_msg}" error
		return ${in_rc}
	}
	unset in_output

# deactivates the project
	out_output=$(cd "${HOME}" 2>&1 && bme_eval_dir 2>&1) || out_rc=$?
	${out_rc} || {
		local err_msg="(${out_rc}) while unloading project config at ${T_BOLD}'${project_dir}'${T_NC}\n"
		err_msg+="${T_BOLD}OUTPUT >>>${T_NC}\n"
		err_msg+=$(indentor "${out_output}" 1)
		err_msg+="\n${T_BOLD}<<< END OF OUTPUT${T_NC}"
		test_log "${err_msg}" error
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

	cd &&  bme_eval_dir || return $?
	test_log "${T_GREEN}OK${T_NC}"
}


function call_virtualenv_without_param() {
	test_title ''

	source bash-magic-enviro || return $?

	cd "${project_dir}" && bme_eval_dir || return $?
	function_output=$(load_virtualenv 2>&1)
	stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"mandatory param 'venv_name' not set".* ]]; then
		test_log "Check ${C_BOLD}'virtualenv without param'${C_NC}: ${C_GREEN}OK${C_NC}" info
	else
		local rc=$?
		local err_msg="Check ${C_BOLD}'virtualenv without param'${C_NC}:\n"
		err_msg+="${T_BOLD}---> OUTPUT START${T_NC}\n"
		err_msg+=$(indentor "${function_output}" 1)
		err_msg+="\n${T_BOLD}<--- OUTPUT END${T_NC}"
		test_log "${err_msg}" error
		return $rc
	fi

	cd &&  bme_eval_dir || return $?
	test_log "${T_GREEN}OK${T_NC}"
}


function create_empty_virtualenv() {
	test_title ''

	source bash-magic-enviro || return $?

	cd "${project_dir}" && bme_eval_dir || return $?
	function_output=$(load_virtualenv 'test-virtualenv' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		local err_msg="Check ${C_BOLD}'empty virtualenv creation'${C_NC}:\n"
		err_msg+="${T_BOLD}---> OUTPUT START${T_NC}\n"
		err_msg+=$(indentor "${function_output}" 1)
		err_msg+="\n${T_BOLD}<--- OUTPUT END${T_NC}"
		test_log "${err_msg}" error
		unset function_output
		return $rc
	fi
	local log_msg="Check ${C_BOLD}'empty virtualenv creation'${C_NC}:\n"
	log_msg+="${T_BOLD}---> OUTPUT START${T_NC}\n"
	log_msg+=$(indentor "${function_output}" 1)
	log_msg+="\n${T_BOLD}<--- OUTPUT END${T_NC}"
	test_log "${log_msg}" ok
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

	cd &&  bme_eval_dir || return $?
	test_log "${C_GREEN}OK${C_NC}"
}


function create_virtualenv_with_extra_param() {
	test_title 'load environment'

	source bash-magic-enviro || return $?

	mkdir --parents "${project_dir}/requirements_subdir" || return $?
	echo 'hello-hello' > "${project_dir}/requirements_subdir/requirements.txt" || return $?
	cd "${project_dir}" && bme_eval_dir || return $?

# Load a virtualenv with parameter
	test_title 'load a simple virtualenv by name'
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		local err_msg="Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}:\n"
		err_msg+="${C_BOLD}---> OUTPUT START${C_NC}\n"
		err_msg+=$(indentor "${function_output}" 1)
		err_msg+="\n${C_BOLD}<--- OUTPUT END${C_NC}"
		test_log "${err_msg}" fail
		unset function_output
		return $rc
	fi
	unset function_output
	bme_log "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}." ok

# Load it again without changes
	test_title "parameterized virtualenv reload"
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		local err_msg="Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}:\n"
		err_msg+="${C_BOLD}---> OUTPUT START${C_NC}\n"
		err_msg+=$(indentor "${function_output}" 1)
		err_msg+="\n${C_BOLD}<--- OUTPUT END${C_NC}"
		test_log "${err_msg}" fail
		unset function_output
		return $rc
	else
		test_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}." ok
	fi

# Load once again, this time with a change
	test_title "load it again, with an update"
	echo -e 'wheel' >> "${project_dir}/requirements_subdir/requirements.txt"
	function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
	if [[ -n $rc ]]; then
		err_msg="Check ${C_BOLD}'parameterized virtualenv update'${C_NC}:\n"
		err_msg+="${C_BOLD}---> OUTPUT START${C_NC}\n"
		err_msg+=$(indentor "${function_output}" 1)
		err_msg+="\n${C_BOLD}<--- OUTPUT END${C_NC}"
		test_log "${err_msg}" fail
		unset function_output
		return $rc
	else
		test_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}." ok
	fi

# Clean
	cd "${HOME}" && bme_eval_dir || return $?
	test_log "virtualenv with parameter management" ok
}


function create_virtualenv_with_custom_pip() {
	test_title "prepare environment"

	source bash-magic-enviro || return $?

# Creates a suitable requirements file
	mkdir --parents "${project_dir}/python-virtualenvs" || return $?
	cat <<- EOF > "${project_dir}/python-virtualenvs/with-pip.requirements"
	example-package-name-mc==0.0.2
	pip==25.0.1
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		local err_msg="WHILE CREATING REQUIREMENTS FILE AT ${T_BOLD}'${project_dir}/python-virtualenvs/with-pip.requirements'${T_NC}.\n"
		if [ -r "${project_dir}/python-virtualenvs/with-pip.requirements" ]; then
			err_msg+="${T_BOLD}---> REQUIREMENTS FILE START${T_NC}\n"
			file_contents=$(<"${project_dir}/python-virtualenvs/with-pip.requirements")
			err_msg+=$(indentor "${file_contents}" 1)
			unset file_contents
			err_msg+="\n${T_BOLD}<--- REQUIREMENTS FILE END${T_NC}"
			test_log "${err_msg}" fail
		else
			test_log "Couldn't find ${T_BOLD}'${project_dir}/python-virtualenvs/with-pip.requirements'${T_NC}." error
		fi
		return $rc_code
	fi
# And then, a suitable .bme_env file
	cat <<- 'EOF' > "${project_dir}/.bme_env"
	load_virtualenv 'with-pip' || return $?
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		local err_msg="WHILE CREATING .bme_env FILE AT ${T_BOLD}'${project_dir}/.bme_env'${T_NC}.\n"
		if [ -r "${project_dir}/.bme_env" ]; then
			file_contents=$(<"${project_dir}/.bme_env")
			err_msg+="${T_BOLD}---> BME_ENV FILE START${T_NC}\n"
			err_msg+=$(indentor "${file_contents}" 1)
			err_msg+="\n${T_BOLD}<--- BME_ENV FILE END${T_NC}"
			unset file_contents
		else
			err_msg+="\tCouldn't find ${T_BOLD}'${project_dir}/python-virtualenvs/with-pip.requirements'${T_NC}."
		fi
		test_log "${err_msg}" error
		return $rc_code
	fi

# Load the environment and check the results
	test_title 'load virtualenv with custom pip'
	cd "${project_dir}" && bme_eval_dir || return $?
	pip freeze --all | grep --quiet 'pip==25.0.1' || {
		test_log "virtualenv with custom pip (see above)" fail
		pip freeze --all
		return 1
	}

	cd &&  bme_eval_dir || return $?
	test_log "virtualenv with custom pip" ok
}


function create_virtualenv_with_includes() {
	test_title 'prepare environment'

	source bash-magic-enviro || return $?

# Creates a suitable requirements file
	mkdir --parents "${project_dir}/python-virtualenvs" || return $?
	cat <<- EOF > "${project_dir}/python-virtualenvs/with-includes.requirements"
	example-package-name-mc==0.0.1
	-r venv-include
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		local err_msg="WHILE CREATING REQUIREMENTS FILE AT ${T_BOLD}'${project_dir}/python-virtualenvs/with-includes.requirements'${T_NC}.\n"
		if [ -r "${project_dir}/python-virtualenvs/with-includes.requirements" ]; then
			file_contents=$(<${project_dir}/python-virtualenvs/with-includes.requirements)
			err_msg+="${T_BOLD}---> REQUIREMENTS FILE START${T_NC}\n"
			err_msg+=$(indentor "${file_contents}" 1)
			err_msg+="\n${T_BOLD}<--- REQUIREMENTS FILE END${T_NC}"
			unset file_contents
		else
			err_msg+="\tCouldn't find ${T_BOLD}'${project_dir}/python-virtualenvs/with-includes.requirements'${T_NC}."
		fi
		test_log "${err_msg}" error
		unset file_contents
		return $rc_code
	fi
# ...and the included one
	cat <<- EOF > "${project_dir}/python-virtualenvs/venv-include"
	wheel==0.45.1
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		local err_msg="WHILE CREATING REQUIREMENTS FILE AT ${T_BOLD}'${project_dir}/python-virtualenvs/venv-include'${T_NC}.\n"
		if [ -r "${project_dir}/python-virtualenvs/venv-include" ]; then
			file_contents=$(<"${project_dir}/python-virtualenvs/venv-include")
			err_msg+="${T_BOLD}---> REQUIREMENTS FILE START${T_NC}\n"
			err_msg+=$(indentor "${file_contents}" 1)
			err_msg+="\n${T_BOLD}<--- REQUIREMENTS FILE END${T_NC}"
			unset file_contents
		else
			err_msg+="\tCouldn't find ${T_BOLD}'${project_dir}/python-virtualenvs/venv-include'${T_NC}."
		fi
		test_log "${err_msg}" error
		unset file_contents
		return $rc_code
	fi

# And then, a suitable .bme_env file
	cat <<- 'EOF' > "${project_dir}/.bme_env"
	load_virtualenv 'with-includes' || return $?
	EOF
	local rc_code=$?
	if (( $rc_code != 0 )); then
		local err_msg="WHILE CREATING .bme_env FILE AT ${T_BOLD}'${project_dir}/.bme_env'${T_NC}.\n"
		if [ -r "${project_dir}/.bme_env" ]; then
			file_contents=$(<"${project_dir}/.bme_env")
			err_msg+="${T_BOLD}---> BME_ENV FILE START${T_NC}\n"
			err_msg+=$(indentor "${file_contents}" 1)
			err_msg+="\n${T_BOLD}<--- BME_ENV FILE END${T_NC}"
			unset file_contents
		else
			err_msg+="\tCouldn't find ${T_BOLD}'${project_dir}/python-virtualenvs/with-includes.requirements'${T_NC}."
		fi
		test_log "${err_msg}" error
		return $rc_code
	fi

# Load the environment and check the results
	test_title 'load virtualenv with includes'
	cd "${project_dir}" && bme_eval_dir || return $?
	pip freeze --all | grep --quiet 'example-package-name-mc==0.0.1' || {
		local err_msg="virtualenv with include doesn't include "
		err_msg+="${T_BOLD}'example-package-name-mc==0.0.1'${T_NC} as it should.\n"
		err_msg+="${T_BOLD}---> PIP FREEZE OUTPUT START${T_NC}\n"
		err_msg+=`pip freeze --all`
		err_msg+="\n${T_BOLD}<--- PIP FREEZE OUTPUT END${T_NC}"
		test_log "${err_msg}" error
		return 1
	}
	pip freeze --all | grep --quiet 'wheel==0.45.1' || {
		local err_msg="virtualenv with include doesn't include "
		err_msg+="${T_BOLD}'wheel==0.45.1'${T_NC} as it should.\n"
		err_msg+="${T_BOLD}---> PIP FREEZE OUTPUT START${T_NC}\n"
		err_msg+=`pip freeze --all`
		err_msg+="\n${T_BOLD}<--- PIP FREEZE OUTPUT END${T_NC}"
		test_log "${err_msg}" error
		return 1
	}

	for venv in 'with-includes' 'venv-include'; do
		grep --quiet "${venv}" "${virtualenvs_md5sums}" || {
			local err_msg="virtualenv ${T_BOLD}'${venv}'${T_NC} md5sum couldn't be found.\n"
			err_msg+="\tat ${T_BOLD}'${virtualenvs_md5sums}'${T_NC}:\n"
			err_msg+="${T_BOLD}---> MD5SUMS FILE START${T_NC}\n"
			err_msg+=`cat "${virtualenvs_md5sums}"`
			err_msg+="\n${T_BOLD}<--- MD5SUMS FILE END${T_NC}"
			test_log "${err_msg}" error
			return 1
		}
	done
	unset venv

	cd &&  bme_eval_dir || return $?
	test_log "virtualenv with includes" ok
}

main; exit $?
