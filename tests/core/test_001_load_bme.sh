#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Loads BME and a "null" project just to attest basic functionality

# User's global environment
export HOME="${SCRATCH_DIR}"
# A first load of BME so its features are enabled along this script
source "${BUILDDIR}/bash-magic-enviro" || exit $?

# Project environment
bme_project_dir="${HOME}/project"
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
cat << EOF > ${BME_WHITELISTED_FILE}
declare -gA BME_WHITELISTED_PATHS=(
	[${bme_project_dir}]=true
)
EOF
echo "---> WHITELIST FILE:"
cat "${HOME}/.bme.d/whitelistedpaths"
echo "<--- END OF WHITELIST FILE"

# Environment ready: reload BME
source "${BUILDDIR}/bash-magic-enviro" || exit $?

# Loads project's configuration
original_env=`printenv | grep -vE 'PWD|OLDPWD'`
	cd $bme_project_dir && bme_eval_dir || exit $?
	cd $HOME && bme_eval_dir || exit $?
unloaded_env=`printenv | grep -vE 'PWD|OLDPWD'`

# there should be no diff between before and after
diff <(echo "$original_env") <(echo "$unloaded_env") || {
	echo "ERROR: loading/unloading a BME project polutes environment (see above)"
	exit 1
}
