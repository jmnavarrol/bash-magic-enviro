#!/usr/bin/env bash

# Meant to be run from maketests.sh.  See its exported variables

# TESTS BME_VERSION value and evaluation

#--
# EVALUATES CURRENT VERSION
#--
# Version should match 'v[number].[number].[number][optional]'
# ...where [optional] starts with '+' or '-', plus an alphanumeric string with dots or hypens.
# See: https://semver.org/
check_current_version() {
	if ! [[ -n ${BME_VERSION} ]]; then
		bme_log "${C_BOLD}'BME_VERSION'${C_NC} undefined!" error
		exit 1
	fi
# Strips version string into its (dot-separated) components: vNN.NN.NN[+|-optional]
# $BASH_REMATCH structure:
# ${BASH_REMATCH[0]} contains the complete match of the regular expression
# ${BASH_REMATCH[1]} contains the match of the 1st () capture group
# ${BASH_REMATCH[2]} contains the match of the 2nd () capture group, and so on.
	if [[ ${BME_VERSION} =~ ^(v[[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)(.*)?$ ]]; then
		declare -A version_components
		version_components['major']=${BASH_REMATCH[1]}
		version_components['minor']=${BASH_REMATCH[2]}
		version_components['patch']=${BASH_REMATCH[3]}
		version_components['optional']=${BASH_REMATCH[4]}
	else
		bme_log "BME version ${C_BOLD}'${BME_VERSION}'${C_NC} doesn't match expected pattern ${C_BOLD}'vNN.NN.NN[optional]'${C_NC}." fail
		exit 1
	fi
# As per Semantic version standard, "patch" level (defined as an integer), may be followed by a pre-release (-[something]) or build metadata (+[something]) suffix
	if [[ -n ${version_components['optional']} ]]; then
		if ! [[ ${version_components['optional']} =~ ^[-\+]([[:alnum:]]|\.|\-)+$ ]]; then
			err_msg="Optional patch extension ${C_BOLD}'${version_components['optional']}'${C_NC} doesn't match expected pattern.\n"
			err_msg+="\tFull version: ${C_BOLD}'${BME_VERSION}'${C_NC}."
			bme_log "${err_msg}" fail
			exit 1
		fi
	fi

	bme_log "Check ${C_BOLD}'BME version formatting'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
}

#--
# EVALUATES bme_check_version()
#--
check_test_version() {
# Testing old version
	BME_VERSION='v0.0.1'
	local function_output=$(bme_check_version)
	local stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"consider upgrading".* ]]; then
		bme_log "Check ${C_BOLD}'BME older version'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
	else
		bme_log "Check ${C_BOLD}'BME older version'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		exit 1
	fi

# Testing unknown version
	BME_VERSION='vasdf'
	local function_output=$(bme_check_version)
	local stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"version couldn't be found at your remote".* ]]; then
		bme_log "Check ${C_BOLD}'BME unknown version'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
	else
		bme_log "Check ${C_BOLD}'BME older version'${C_NC}: ${C_RED}FAIL${C_NC}"
		bme_log "${C_BOLD}OUTPUT${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
		exit 1
	fi
}

#--
# MAIN
#--
export HOME="${SCRATCH_DIR}"
source "${BUILDDIR}/bash-magic-enviro"
check_current_version
check_test_version
