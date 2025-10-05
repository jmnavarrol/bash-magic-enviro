#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests BME_VERSION format and value

function main() {
	source bash-magic-enviro || exit $?
	check_version_format || exit $?
	check_test_version_function || exit $?
	check_version_assert || exit $?
}


#--
# EVALUATES CURRENT VERSION's FORMAT
#--
function check_version_format() {

	test_title "assert version variable"
	if ! [[ -n ${BME_VERSION} ]]; then
		test_log "${C_BOLD}'BME_VERSION'${C_NC} undefined!" error
		return 1
	else
		test_log "${C_BOLD}'BME_VERSION'${C_NC} is defined: ${T_BOLD}'${BME_VERSION}'${T_NC}" ok
	fi

# Strips version string into its (dot-separated) components: vNN.NN.NN[+|-optional]
# $BASH_REMATCH structure:
# ${BASH_REMATCH[0]} contains the complete match of the regular expression
# ${BASH_REMATCH[1]} contains the match of the 1st () capture group
# ${BASH_REMATCH[2]} contains the match of the 2nd () capture group, and so on.
	test_title "check version pattern"
	if [[ ${BME_VERSION} =~ ^(v[[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)(.*)?$ ]]; then
		test_log "BME version ${C_BOLD}'${BME_VERSION}'${C_NC} follows the expected basic ${C_BOLD}'vNN.NN.NN[optional]'${C_NC} pattern." ok

		declare -A version_components
		version_components['major']=${BASH_REMATCH[1]}
		version_components['minor']=${BASH_REMATCH[2]}
		version_components['patch']=${BASH_REMATCH[3]}
		version_components['optional']=${BASH_REMATCH[4]}
	else
		test_log "BME version ${C_BOLD}'${BME_VERSION}'${C_NC} doesn't match expected pattern ${C_BOLD}'vNN.NN.NN[optional]'${C_NC}." fail
		return 1
	fi

# As per Semantic version standard, "patch" level (defined as an integer), may be followed by a pre-release (-[something]) or build metadata (+[something]) suffix
	test_title "check post-extraversion pattern"
	if [[ -n ${version_components['optional']} ]]; then
		if ! [[ ${version_components['optional']} =~ ^[-\+]([[:alnum:]]|\.|\-)+$ ]]; then
			err_msg="Optional patch extension ${C_BOLD}'${version_components['optional']}'${C_NC} doesn't match expected pattern.\n"
			err_msg+="\tFull version: ${C_BOLD}'${BME_VERSION}'${C_NC}."
			test_log "${err_msg}" fail
			return 1
		else
			test_log "Optional patch extension ${C_BOLD}'${version_components['optional']}'${C_NC} matches de expected pattern." ok
		fi
	else
		test_log "Version '${C_BOLD}'${BME_VERSION}'${C_NC}' doesn't have optional patch extension." info
	fi

	test_log "Check ${C_BOLD}'BME version formatting'${C_NC}: ${C_GREEN}OK${C_NC}" info
}


#--
# EVALUATES bme_check_version()
#--
check_test_version_function() {
# Testing old version
	test_title "check for older version"
	BME_VERSION='v0.0.1'
	local function_output=$(bme_check_version)
	local stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"consider upgrading".* ]]; then
		bme_log "Version ${C_BOLD}'${BME_VERSION}'${C_NC} is older than current." ok 1
	else
		bme_log "Version ${C_BOLD}'${BME_VERSION}'${C_NC} is older than current." fail 1
		bme_log "${C_BOLD}bme_check_version() output follows:${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}end of bme_check_version() output.${C_NC}"
		return 1
	fi

# Testing unknown version
	test_title "check for unknown version"
	BME_VERSION='vasdf'
	local function_output=$(bme_check_version)
	local stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"version couldn't be found at your remote".* ]]; then
		bme_log "Version ${C_BOLD}'${BME_VERSION}'${C_NC} is unknown." ok 1
	else
		bme_log "Check ${C_BOLD}'BME older version'${C_NC}." fail 1
		bme_log "${C_BOLD}bme_check_version() output follows:${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}end of bme_check_version() output.${C_NC}"
		return 1
	fi

	test_log "Check ${C_BOLD}'bme_check_version()'${C_NC} function: ${C_GREEN}OK${C_NC}" info
}


#--
# ASSERTS CURRENT BME VERSION AGAINST A MATCHING REQUEST
#--
check_version_assert() {
# TBD
	test_title "assert version against request"
	test_log "YET TO BE DONE" fail
	return 1
}

main; exit $?
