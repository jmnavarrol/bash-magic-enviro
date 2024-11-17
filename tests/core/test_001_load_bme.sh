#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Loads BME and a "null" project just to attest basic functionality
test_title "Loads BME and a "null" project just to attest basic functionality:"

# User's global environment
# A first load of BME so its features are enabled along this script
source bash-magic-enviro || exit $?

# Project environment
bme_project_dir="${HOME}/project"
mkdir --parents ${bme_project_dir}

# Creates a minimal project file
cat <<- EOF > "${bme_project_dir}/.bme_project"
# This is a test BME project
BME_PROJECT_NAME='project'
EOF
file_contents=`cat "${bme_project_dir}/.bme_project"`
test_log "${T_BOLD}---> BME PROJECT FILE START${T_NC}"
test_log "${file_contents}"
test_log "${T_BOLD}<--- BME PROJECT FILE END${T_NC}"

# whitelists the project
cat << EOF > ${BME_WHITELISTED_FILE}
declare -gA BME_WHITELISTED_PATHS=(
	[${bme_project_dir}]=true
)
EOF
file_contents=`cat "${HOME}/.bme.d/whitelistedpaths"`
test_log "${T_BOLD}---> WHITELIST FILE START${T_NC}"
test_log "${file_contents}"
test_log "${T_BOLD}<--- WHITELIST FILE END${T_NC}"

# Environment ready: reload BME
source bash-magic-enviro || exit $?

# Loads project's configuration
original_env=`printenv | grep -vE 'PWD|OLDPWD'`
	cd $bme_project_dir && bme_eval_dir || exit $?
	cd $HOME && bme_eval_dir || exit $?
unloaded_env=`printenv | grep -vE 'PWD|OLDPWD'`

# there should be no diff between before and after
diff <(echo "$original_env") <(echo "$unloaded_env") || {
	test_log "loading/unloading a BME project polutes environment (see above)" error
	exit 1
}

test_log "${T_GREEN}OK${T_NC}"
