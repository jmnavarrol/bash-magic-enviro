#!/usr/bin/env bash

# TESTS loading/unloading of .bme_env files

# Creates a project within SCRATCH_DIR
prepare_environment() {
	export HOME="${SCRATCH_DIR}"
	export CUSTOM_PROJECT_DIR="${HOME}/test_project"
# custom project
	mkdir "${CUSTOM_PROJECT_DIR}"
# custom .bme_project file
	cat <<- EOF > "${CUSTOM_PROJECT_DIR}/.bme_project"
	BME_PROJECT_NAME='test_project'
	EOF

	echo "---> BME PROJECT FILE:"
	cat "${CUSTOM_PROJECT_DIR}/.bme_project"
	echo "<--- END OF BME PROJECT FILE"
# project whitelisting
	mkdir "${HOME}/.bme.d"
	cat <<- EOF > "${HOME}/.bme.d/whitelistedpaths"
	declare -gA BME_WHITELISTED_PATHS=(
		[${CUSTOM_PROJECT_DIR}]=true
	)
	EOF

	echo "---> WHITELIST FILE:"
	cat "${HOME}/.bme.d/whitelistedpaths"
	echo "<--- END OF WHITELIST FILE"
}


# tests single .bme_env file at project dir
check_root_bme_env() {
# custom root .bme_env
	cat <<- EOF > "${CUSTOM_PROJECT_DIR}/.bme_env"
	echo "LOADING ROOT .BME_ENV AT '${CUSTOM_PROJECT_DIR}'."
	EOF
# within a subshell to avoid environment corruption
	(
		source "${BUILDDIR}/bash-magic-enviro"
		cd "${CUSTOM_PROJECT_DIR}"
		local function_output=$(bme_eval_dir)
		local stripped_output=$(strip_escape_codes "${function_output}")

	# assert-like
		if ! [[ "${stripped_output}" =~ .*"LOADING ROOT .BME_ENV AT '${CUSTOM_PROJECT_DIR}'.".* ]]; then
			echo "${function_output}"
			echo "ERROR: '${FUNCNAME}') test FAILED."
			return 1
		fi
	) || return $?
}


# Reaches a deep .bme_env file in a single drop
check_deep_bme_env() {
# custom deep .bme_env
	mkdir "${CUSTOM_PROJECT_DIR}/deeper"
	cat <<- EOF > "${CUSTOM_PROJECT_DIR}/deeper/.bme_env"
	echo "LOADING DEEPER .BME_ENV AT '${CUSTOM_PROJECT_DIR}/deeper'."
	EOF
# within a subshell to avoid environment corruption
	(
		source "${BUILDDIR}/bash-magic-enviro"
		cd "${CUSTOM_PROJECT_DIR}/deeper"
		local function_output=$(bme_eval_dir)
		local stripped_output=$(strip_escape_codes "${function_output}")

		local root_match_count=$(
			echo "$stripped_output" \
			| grep --extended-regexp --count \
			.*"LOADING ROOT .BME_ENV AT '${CUSTOM_PROJECT_DIR}'.".*
		)
	# Root .bme_env file should be loaded exactly once
		if (( 1 != ${root_match_count} )); then
			echo "${function_output}"
			echo "ERROR: '${FUNCNAME}' test FAILED."
			echo "ROOT .bme_env WASN'T LOADED EXACTLY ONCE (count '${root_match_count}')."
			return 1
		fi
	# Deeper .bme_env file should also be loaded
		if ! [[ "${stripped_output}" =~ .*"LOADING DEEPER .BME_ENV AT '${CUSTOM_PROJECT_DIR}/deeper'.".* ]]; then
			echo "${function_output}"
			echo "ERROR: '${FUNCNAME}' test FAILED."
			echo "DEEPER .bme_env WASN'T PROPERLY LOADED."
			return 1
		fi
	) || return $?
}


# Goes in and out subdirectories
check_back_and_forth() {
	mkdir "${CUSTOM_PROJECT_DIR}/other"
# within a subshell to avoid environment corruption
	(
		source "${BUILDDIR}/bash-magic-enviro"
		local function_output=$(
			cd "${CUSTOM_PROJECT_DIR}/other" && bme_eval_dir
			cd "${CUSTOM_PROJECT_DIR}/deeper" && bme_eval_dir
		)
		local stripped_output=$(strip_escape_codes "${function_output}")

		root_match_count=$(
			echo "$stripped_output" \
			| grep --extended-regexp --count \
			.*"LOADING ROOT .BME_ENV AT '${CUSTOM_PROJECT_DIR}'.".*
		)

		if (( 1 != ${root_match_count} )); then
			echo "${function_output}"
			echo "ERROR: '${FUNCNAME}' test FAILED."
			echo "ROOT .bme_env WASN'T LOADED EXACTLY ONCE (count '${root_match_count}')."
			return 1
		fi

		if ! [[ "${stripped_output}" =~ .*"LOADING DEEPER .BME_ENV AT '${CUSTOM_PROJECT_DIR}/deeper'.".* ]]; then
			echo "${function_output}"
			echo "ERROR: '${FUNCNAME}' test FAILED."
			echo "DEEPER .bme_env WASN'T PROPERLY LOADED."
			return 1
		fi
	) || return $?
}


#--
# ENTRY POINT
#--
prepare_environment || exit $?
check_root_bme_env || exit $?
check_deep_bme_env || exit $?
check_back_and_forth || exit $?

