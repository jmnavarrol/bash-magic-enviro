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
	cd "${bme_project_dir}" && bme_eval_dir || return $?
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
	mkdir --parents ${bme_project_dir}

# Creates a minimal project file
	cat <<- EOF > "${bme_project_dir}/.bme_project"
	# This is a test BME project
	BME_PROJECT_NAME='project'
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
	cat "${HOME}/.bme.d/whitelistedpaths"
	echo "<--- END OF WHITELIST FILE"

# reloads for changes to be updated
	source bash-magic-enviro || exit $?
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
	for global_var in "${global_vars}"; do
		if [[ -n ${!global_var+x} ]]; then
			bme_log "global var '${global_var}' set: '${!global_var}'" info 1
		else
			bme_log "'${global_var}' UNSET: '${!global_var}'" error 1
			return 1
		fi
	done
	unset global_var

# Project-level vars shouldn't be already set
	for project_var in "${project_vars[@]}"; do
		if [[ -n ${!project_var+x} ]]; then
			bme_log "project-level var '${project_var}' set before any project loaded: '${!project_var}'" error 1
			return 1
		else
			bme_log "project-level var '${project_var}' unset: '${!project_var}'" info 1
		fi
	done
	unset project_var
}

# Checks that project-level envvars are there
function __assert_project_envvars() {
local project_vars=(
	'BME_PROJECT_NAME'
	'BME_PROJECT_DIR'
	'BME_PROJECT_CONFIG_DIR'
)

	for project_var in "${project_vars[@]}"; do
		if [[ -n ${!project_var+x} ]]; then
			bme_log "project var '${project_var}' set: '${!project_var}'" info 1
		else
			bme_log "'${project_var}' UNSET: '${!project_var}'" error 1
			return 1
		fi
	done
	unset project_var
}

# Checks that project-level envvars are there
function __assert_no_project_envvars() {
local project_vars=(
	'BME_PROJECT_NAME'
	'BME_PROJECT_DIR'
	'BME_PROJECT_CONFIG_DIR'
)

	for project_var in "${project_vars[@]}"; do
		if [[ -n ${!project_var+x} ]]; then
			bme_log "project var '${project_var}' set: '${!project_var}'" error 1
			return 1
		else
			bme_log "'${project_var}' UNSET: '${!project_var}'" info 1
		fi
	done
	unset project_var
}

# Checks the usage of a custom project's config dir
__assert_custom_project_config_dir() {
# Use a relative custom config dir
	cp -a "${bme_project_dir}/.bme_project" "${bme_project_dir}/.bme_project.orig"
	echo "BME_PROJECT_CONFIG_DIR='.custom.d'" >> "${bme_project_dir}/.bme_project"
	echo "---> BME PROJECT FILE:"
	cat "${bme_project_dir}/.bme_project"
	echo "<--- END OF BME PROJECT FILE"

	cd "${bme_project_dir}" && bme_eval_dir || return $?
	if [ "${BME_PROJECT_CONFIG_DIR}" != "${bme_project_dir}/.custom.d" ]; then
		local err_msg="BME_PROJECT_CONFIG_DIR points to ${C_BOLD}'${BME_PROJECT_CONFIG_DIR}'${C_NC}"
		err_msg+=" instead of ${C_BOLD}'${bme_project_dir}/.custom.d'${C_NC} as it should."
		bme_log "${err_msg}" error 1
		return 1
	fi
	# the directory must exist
	if [ ! -d "${BME_PROJECT_CONFIG_DIR}" ]; then
		local err_msg="BME_PROJECT_CONFIG_DIR's directory ${C_BOLD}'${BME_PROJECT_CONFIG_DIR}'${C_NC}"
		err_msg+=" doesn't exist, as it should."
		bme_log "${err_msg}" error 1
		return 1
	fi
	# Restore the original project file
	cd "${HOME}" && bme_eval_dir || return $?
	rm -rf "${bme_project_dir}/.custom.d"
	mv "${bme_project_dir}/.bme_project.orig" "${bme_project_dir}/.bme_project"

# Use an absolute custom config dir
	local absolute_config_dir="${HOME}/.custom.d"

	cp -a "${bme_project_dir}/.bme_project" "${bme_project_dir}/.bme_project.orig"
	echo "BME_PROJECT_CONFIG_DIR='${absolute_config_dir}'" >> "${bme_project_dir}/.bme_project"
	echo "---> BME PROJECT FILE:"
	cat "${bme_project_dir}/.bme_project"
	echo "<--- END OF BME PROJECT FILE"

	cd "${bme_project_dir}" && bme_eval_dir || return $?
	if [ "${BME_PROJECT_CONFIG_DIR}" != "${absolute_config_dir}" ]; then
		local err_msg="BME_PROJECT_CONFIG_DIR points to ${C_BOLD}'${BME_PROJECT_CONFIG_DIR}'${C_NC}"
		err_msg+=" instead of ${C_BOLD}'${absolute_config_dir}'${C_NC} as it should."
		bme_log "${err_msg}" error 1
		return 1
	fi
	# the directory must exist
	if [ ! -d "${BME_PROJECT_CONFIG_DIR}" ]; then
		local err_msg="BME_PROJECT_CONFIG_DIR's directory ${C_BOLD}'${BME_PROJECT_CONFIG_DIR}'${C_NC}"
		err_msg+=" doesn't exist, as it should."
		bme_log "${err_msg}" error 1
		return 1
	fi
	# Restore the original project file
	cd "${HOME}" && bme_eval_dir || return $?
	rm -rf "${absolute_config_dir}"
	mv "${bme_project_dir}/.bme_project.orig" "${bme_project_dir}/.bme_project"
}

main; exit $?
