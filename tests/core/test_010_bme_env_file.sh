#!/usr/bin/env bash

# TESTS loading/unloading of .bme_env files
# Controller (see the end of this file)
function main() {
	prepare_environment || exit $?
	check_root_bme_env || exit $?
	check_deep_bme_env || exit $?
	check_back_and_forth || exit $?
}


# Creates a project within SCRATCH_DIR
prepare_environment() {
	test_title ''

	export CUSTOM_PROJECT_DIR="${HOME}/test_project"
# custom project
	mkdir "${CUSTOM_PROJECT_DIR}"
# custom .bme_project file
	cat <<- EOF > "${CUSTOM_PROJECT_DIR}/.bme_project"
	BME_PROJECT_NAME='test_project'
	EOF
	file_contents=`cat "${CUSTOM_PROJECT_DIR}/.bme_project"`

	test_log "${T_BOLD}---> BME PROJECT FILE START${T_NC}"
	test_log "${file_contents}"
	test_log "${T_BOLD}<--- BME PROJECT FILE END${T_NC}"

# project whitelisting
	mkdir "${HOME}/.bme.d"
	cat <<- EOF > "${HOME}/.bme.d/whitelistedpaths"
	declare -gA BME_WHITELISTED_PATHS=(
		[${CUSTOM_PROJECT_DIR}]=true
	)
	EOF
	file_contents=`cat "${HOME}/.bme.d/whitelistedpaths"`

	test_log "${T_BOLD}---> WHITELIST FILE START${T_NC}"
	test_log "${file_contents}"
	test_log "${T_BOLD}<--- WHITELIST FILE END${T_NC}"

	unset file_contents
	test_log "${T_GREEN}OK${T_NC}"
}


# tests single .bme_env file at project dir
check_root_bme_env() {
	test_title "asserts that '.bme_env' at project's root loads properly"

# custom root .bme_env
	cat <<- EOF > "${CUSTOM_PROJECT_DIR}/.bme_env"
	echo "LOADING ROOT .BME_ENV AT '${CUSTOM_PROJECT_DIR}'."
	EOF
	file_contents=`cat "${CUSTOM_PROJECT_DIR}/.bme_env"`
	test_log "${T_BOLD}---> BME_ENV FILE START${T_NC}"
	test_log "${file_contents}"
	test_log "${T_BOLD}<--- BME_ENV FILE END${T_NC}"

# within a subshell to avoid environment corruption
	(
		source bash-magic-enviro
		cd "${CUSTOM_PROJECT_DIR}"
		local function_output=$(bme_eval_dir)
		local stripped_output=$(strip_escape_codes "${function_output}")

	# assert-like
		if ! [[ "${stripped_output}" =~ .*"LOADING ROOT .BME_ENV AT '${CUSTOM_PROJECT_DIR}'.".* ]]; then
			test_log "while running ${T_BOLD}'${FUNCNAME}${T_NC}':" error
			test_log "${T_BOLD}---> OUTPUT START${T_NC}" '' 2
			test_log "${function_output}" '' 2
			test_log "${T_BOLD}<--- OUTPUT END${T_NC}" '' 2
			return 1
		fi
	) || return $?

	unset file_contents
	test_log "${T_GREEN}OK${T_NC}"
}


# Reaches a deep .bme_env file in a single drop
check_deep_bme_env() {
	test_title 'Reaches a deep .bme_env file in a single drop'

# custom deep .bme_env
	mkdir "${CUSTOM_PROJECT_DIR}/deeper"
	cat <<- EOF > "${CUSTOM_PROJECT_DIR}/deeper/.bme_env"
	echo "LOADING DEEPER .BME_ENV AT '${CUSTOM_PROJECT_DIR}/deeper'."
	EOF
	file_contents=`cat "${CUSTOM_PROJECT_DIR}/deeper/.bme_env"`
	test_log "${T_BOLD}---> DEEP BME_ENV FILE START${T_NC}"
	test_log "${file_contents}"
	test_log "${T_BOLD}<--- DEEP BME_ENV FILE END${T_NC}"

# within a subshell to avoid environment corruption
	(
		source bash-magic-enviro
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
			local err_msg="while running ${T_BOLD}'${FUNCNAME}${T_NC}':"
			err_msg+="\n\tROOT .bme_env WASN'T LOADED EXACTLY ONCE (count '${root_match_count}')."
			test_log "${err_msg}" error
			return 1
		fi
	# Deeper .bme_env file should also be loaded
		if ! [[ "${stripped_output}" =~ .*"LOADING DEEPER .BME_ENV AT '${CUSTOM_PROJECT_DIR}/deeper'.".* ]]; then
			local err_msg="while running ${T_BOLD}'${FUNCNAME}${T_NC}':"
			err_msg+="\n\tDEEPER .bme_env WASN'T PROPERLY LOADED."
			test_log "${err_msg}" error
			test_log "${T_BOLD}---> OUTPUT START${T_NC}" '' 2
			test_log "${function_output}" '' 2
			test_log "${T_BOLD}<--- OUTPUT END${T_NC}" '' 2
			return 1
		fi
	) || return $?

	unset file_contents
	test_log "${T_GREEN}OK${T_NC}"
}


# Goes in and out subdirectories
check_back_and_forth() {
	test_title "goes in and out subirectories"

	mkdir "${CUSTOM_PROJECT_DIR}/other"
# within a subshell to avoid environment corruption
	(
		source bash-magic-enviro
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
			local err_msg="while running ${T_BOLD}'${FUNCNAME}${T_NC}':"
			err_msg+="\n\tROOT .bme_env WASN'T LOADED EXACTLY ONCE (count '${root_match_count}')."
			test_log "${err_msg}" error
			return 1
		fi

		if ! [[ "${stripped_output}" =~ .*"LOADING DEEPER .BME_ENV AT '${CUSTOM_PROJECT_DIR}/deeper'.".* ]]; then
			local err_msg="while running ${T_BOLD}'${FUNCNAME}${T_NC}':"
			err_msg+="\n\tDEEPER .bme_env WASN'T PROPERLY LOADED."
			test_log "${err_msg}" error
			test_log "${T_BOLD}---> OUTPUT START${T_NC}" '' 2
			test_log "${function_output}" '' 2
			test_log "${T_BOLD}<--- OUTPUT END${T_NC}" '' 2
			return 1
		fi
	) || return $?

	test_log "${T_GREEN}OK${T_NC}"
}


# ENTRY POINT (redirects to main at the head of this file)
main; exit $?
