#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests "public" environment variables to be customizable
function main() {
	bme_project_dir="${HOME}/project"

# A first load of BME so its features are enabled along this script
	source bash-magic-enviro || exit $?

# Prepares a project environment
	__create_project || return $?
# "Public" environment variables as per specs should be there
	__assert_global_envvars
# project-level vars shoud be there once within a project
	__assert_project_envvars
# project-level vars should NOT be there once moving out a project
	cd "${HOME}" && bme_eval_dir || return $?
	__assert_no_project_envvars
# testing the use of a project's custom config dir
	__assert_custom_project_config_dir
}

#--
# HELPER FUNCTIONS
#--
function __create_project() {
	test_title "Creates a test project:"

# Creates a minimal project file
	mkdir --parents ${bme_project_dir} || return $?
	cat <<- EOF > "${bme_project_dir}/.bme_project"
	# This is a test BME project
	BME_PROJECT_NAME='project'
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
	unset file_contents

# reloads the global config for the whitelisting to take effect
	source bash-magic-enviro || exit $?
	test_log "${T_GREEN}OK${T_NC}"
}


# Checks that "global" public envvars are there
# ...and that no other public envvars are there
function __assert_global_envvars() {
local global_vars=(
	'BME_CONFIG_DIR'
)
local project_vars=(
	'BME_PROJECT_DIR'
	'BME_PROJECT_CONFIG_DIR'
	'BME_PROJECT_NAME'
)

# Global vars shoud be set
	test_title "checks BME global vars:"
	for global_var in "${global_vars}"; do
		if [[ -n ${!global_var+x} ]]; then
			test_log "global var ${T_BOLD}'${global_var}'${T_NC} set: ${T_BOLD}'${!global_var}'${T_NC}" info
		else
			test_log "${T_BOLD}'${global_var}'${T_NC} UNSET: ${T_BOLD}'${!global_var}'${T_NC}" error
			return 1
		fi
	done
	unset global_var
	test_log "${T_GREEN}OK${T_NC}"

# Project-level vars shouldn't be already set
	test_title "BME project vars shouldn't yet be set:"
	for project_var in "${project_vars[@]}"; do
		if [[ -n ${!project_var+x} ]]; then
			bme_log "project-level var ${T_BOLD}'${project_var}'${T_NC} set before any project loaded: ${T_BOLD}'${!project_var}'${T_NC}" error 1
			return 1
		else
			bme_log "project-level var ${T_BOLD}'${project_var}'${T_NC} unset: ${T_BOLD}'${!project_var}'${T_NC}" info
		fi
	done
	unset project_var
	test_log "${T_GREEN}OK${T_NC}"
}


# Checks that project-level envvars are there
function __assert_project_envvars() {
local project_vars=(
	'BME_PROJECT_NAME'
	'BME_PROJECT_DIR'
	'BME_PROJECT_CONFIG_DIR'
)

	test_title "assert project envvars are properly set:"
	cd "${bme_project_dir}" && bme_eval_dir || return $?
	for project_var in "${project_vars[@]}"; do
		if [[ -n ${!project_var+x} ]]; then
			test_log "project var ${T_BOLD}'${project_var}'${T_NC} set: ${T_BOLD}'${!project_var}'${T_NC}" info
		else
			test_log "${T_BOLD}'${project_var}'${T_NC} UNSET: ${T_BOLD}'${!project_var}'${T_NC}" error
			return 1
		fi
	done
	unset project_var
	test_log "${T_GREEN}OK${T_NC}"
}

# Checks that project-level envvars are there
function __assert_no_project_envvars() {
local project_vars=(
	'BME_PROJECT_NAME'
	'BME_PROJECT_DIR'
	'BME_PROJECT_CONFIG_DIR'
)

	test_title "assert project envvars are properly cleaned out"
	cd "${HOME}" && bme_eval_dir || return $?
	for project_var in "${project_vars[@]}"; do
		if [[ -n ${!project_var+x} ]]; then
			test_log "project var ${T_BOLD}'${project_var}'${T_NC} set: ${T_BOLD}'${!project_var}'${T_NC}" error
			return 1
		else
			test_log "${T_BOLD}'${project_var}'${T_NC} UNSET: ${T_BOLD}'${!project_var}'${T_NC}" info
		fi
	done
	unset project_var
	test_log "${T_GREEN}OK${T_NC}"
}

# Checks the usage of a custom project's config dir
__assert_custom_project_config_dir() {

	cd "${HOME}" || return $?

# Use a relative custom project config dir
	test_title "test the usage of a relative custom project config dir"

	cp -a "${bme_project_dir}/.bme_project" "${bme_project_dir}/.bme_project.orig"
	echo "BME_PROJECT_CONFIG_DIR='.custom.d'" >> "${bme_project_dir}/.bme_project"
	file_contents=`cat "${bme_project_dir}/.bme_project"`
	test_log "${T_BOLD}---> PROJECT FILE START${T_NC}"
	test_log "${file_contents}"
	test_log "${T_BOLD}<--- PROJECT FILE END${T_NC}"

	cd "${bme_project_dir}" && bme_eval_dir || return $?
	if [ "${BME_PROJECT_CONFIG_DIR}" != "${bme_project_dir}/.custom.d" ]; then
		local err_msg="BME_PROJECT_CONFIG_DIR points to ${C_BOLD}'${BME_PROJECT_CONFIG_DIR}'${C_NC}"
		err_msg+=" instead of ${C_BOLD}'${bme_project_dir}/.custom.d'${C_NC} as it should."
		test_log "${err_msg}" error
		return 1
	fi
	# the directory must exist
	if [ ! -d "${BME_PROJECT_CONFIG_DIR}" ]; then
		local err_msg="BME_PROJECT_CONFIG_DIR's directory ${C_BOLD}'${BME_PROJECT_CONFIG_DIR}'${C_NC}"
		err_msg+=" doesn't exist, as it should."
		test_log "${err_msg}" error
		return 1
	fi
	# Restore the original project file
	cd "${HOME}" && bme_eval_dir || return $?
	rm -rf "${bme_project_dir}/.custom.d"
	mv "${bme_project_dir}/.bme_project.orig" "${bme_project_dir}/.bme_project"

	test_log "${T_GREEN}OK${T_NC}"

# Use an absolute custom config dir
	test_title "test the usage of an absolute custom project config dir"
	local absolute_config_dir="${HOME}/.custom.d"

	cp -a "${bme_project_dir}/.bme_project" "${bme_project_dir}/.bme_project.orig"
	echo "BME_PROJECT_CONFIG_DIR='${absolute_config_dir}'" >> "${bme_project_dir}/.bme_project"
	file_contents=`cat "${bme_project_dir}/.bme_project"`
	test_log "${T_BOLD}---> PROJECT FILE START${T_NC}"
	test_log "${file_contents}"
	test_log "${T_BOLD}<--- PROJECT FILE END${T_NC}"

	cd "${bme_project_dir}" && bme_eval_dir || return $?
	if [ "${BME_PROJECT_CONFIG_DIR}" != "${absolute_config_dir}" ]; then
		local err_msg="BME_PROJECT_CONFIG_DIR points to ${C_BOLD}'${BME_PROJECT_CONFIG_DIR}'${C_NC}"
		err_msg+=" instead of ${C_BOLD}'${absolute_config_dir}'${C_NC} as it should."
		test_log "${err_msg}" error
		return 1
	fi
	# the directory must exist
	if [ ! -d "${BME_PROJECT_CONFIG_DIR}" ]; then
		local err_msg="BME_PROJECT_CONFIG_DIR's directory ${C_BOLD}'${BME_PROJECT_CONFIG_DIR}'${C_NC}"
		err_msg+=" doesn't exist, as it should."
		test_log "${err_msg}" error
		return 1
	fi
	# Restore the original project file
	cd "${HOME}" && bme_eval_dir || return $?
	rm -rf "${absolute_config_dir}"
	mv "${bme_project_dir}/.bme_project.orig" "${bme_project_dir}/.bme_project"

	unset file_contents
	test_log "${T_GREEN}OK${T_NC}"
}

main; exit $?
