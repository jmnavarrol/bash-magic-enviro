#!/usr/bin/env bash

# Meant to be run from maketests.sh.  See its exported variables
# TESTS loading/unloading of .bme_env files

# prepares the environment for tests
prepare_environment() {
# project environment
	export BME_PROJECT_DIR="${SCRATCH_DIR}/test-project"
	mkdir --parents "${BME_PROJECT_DIR}"
# custom .bme_project
	cat <<- EOF > "${BME_PROJECT_DIR}/.bme_project"
	BME_PROJECT_NAME='test_project'
	EOF
# custorm root .bme_env
	cat <<- EOF > "${BME_PROJECT_DIR}/.bme_env"
	echo "LOADING ROOT .BME_ENV AT '${BME_PROJECT_DIR}'."
	EOF
# deeper .bme_env
	mkdir --parents "${BME_PROJECT_DIR}/deeper"
	cat <<- EOF > "${BME_PROJECT_DIR}/deeper/.bme_env"
	echo "LOADING DEEPER .BME_ENV AT '${BME_PROJECT_DIR}/deeper'."
	EOF
# project whitelisting
	mkdir --parents "${HOME}/${BME_HIDDEN_DIR}"
	cat <<- EOF > "${HOME}/.bme.d/whitelistedpaths"
	declare -gA BME_WHITELISTED_PATHS=(
		[${BME_PROJECT_DIR}]=true
	)
	EOF

	source "${BME_FULL_PATH}" || exit $?
# 	export DEBUG=$true
}


# single .bme_env file at project root
check_root_bme_env() {
	cd "${BME_PROJECT_DIR}"
	local function_output=$(bme_eval_dir)
	local stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"LOADING ROOT .BME_ENV AT '${BME_PROJECT_DIR}'.".* ]]; then
		bme_log "Check ${C_BOLD}'Load root .bme_env file'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
	else
		bme_log "Check ${C_BOLD}'Load root .bme_env file'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		exit 1
	fi
}

# Reaches a deep .bme_env file in a single drop
check_deep_bme_env() {
	cd "${BME_PROJECT_DIR}/deeper"
	local function_output=$(bme_eval_dir)
	local stripped_output=$(strip_escape_codes "${function_output}")

	local root_match_count=$(echo "$stripped_output" \
	| grep --extended-regexp --count .*"LOADING ROOT .BME_ENV AT '${BME_PROJECT_DIR}'.".*)

	if (( 1 != ${root_match_count} )); then
		bme_log "Check ${C_BOLD}'Load deep .bme_env file'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		bme_log "Root .bme_file wasn't loaded properly (${root_match_count} instead of 1)." error 1
		exit 1
	fi

	if ! [[ "${stripped_output}" =~ .*"LOADING DEEPER .BME_ENV AT '${BME_PROJECT_DIR}/deeper'.".* ]]; then
		bme_log "Check ${C_BOLD}'Load deep .bme_env file'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		exit 1
	fi
# If we reached here, everything went OK
	bme_log "Check ${C_BOLD}'Load deep .bme_env file'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
}


# Goes in and out subdirectories
check_back_and_forth() {
	mkdir --parents "${BME_PROJECT_DIR}/other"
	local function_output=$(
		cd "${BME_PROJECT_DIR}/other" && bme_eval_dir
		cd "${BME_PROJECT_DIR}/deeper" && bme_eval_dir
	)
	local stripped_output=$(strip_escape_codes "${function_output}")

	root_match_count=$(echo "$stripped_output" \
	| grep --extended-regexp --count .*"LOADING ROOT .BME_ENV AT '${BME_PROJECT_DIR}'.".*)

	if (( 1 != ${root_match_count} )); then
		bme_log "Check ${C_BOLD}'Load deep .bme_env file'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		bme_log "Root .bme_file wasn't loaded properly (${root_match_count} instead of 1)." error 1
		exit 1
	fi

	if ! [[ "${stripped_output}" =~ .*"LOADING DEEPER .BME_ENV AT '${BME_PROJECT_DIR}/deeper'.".* ]]; then
		bme_log "Check ${C_BOLD}'Load deep .bme_env file'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		exit 1
	fi
# If we reached here, everything went OK
	rm --recursive --force "${BME_PROJECT_DIR}/other"
	bme_log "Check ${C_BOLD}'Back and forth .bme_env file'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
}


#--
# MAIN
#--
prepare_environment
check_root_bme_env
check_deep_bme_env
check_back_and_forth
