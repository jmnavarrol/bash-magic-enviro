#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests BME_VERSION format and value

function main() {
	export HOME="${SCRATCH_DIR}"
	source "${BUILDDIR}/bash-magic-enviro"
	check_version_format || exit $?
	check_test_version_function || exit $?
}


#--
# EVALUATES CURRENT VERSION's FORMAT
#--
function check_version_format() {
	if ! [[ -n ${BME_VERSION} ]]; then
		bme_log "${C_BOLD}'BME_VERSION'${C_NC} undefined!" error 1
		return 1
	else
		bme_log "${C_BOLD}'BME_VERSION'${C_NC} is defined!" ok 1
	fi

# Strips version string into its (dot-separated) components: vNN.NN.NN[+|-optional]
# $BASH_REMATCH structure:
# ${BASH_REMATCH[0]} contains the complete match of the regular expression
# ${BASH_REMATCH[1]} contains the match of the 1st () capture group
# ${BASH_REMATCH[2]} contains the match of the 2nd () capture group, and so on.
	if [[ ${BME_VERSION} =~ ^(v[[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)(.*)?$ ]]; then
		bme_log "BME version ${C_BOLD}'${BME_VERSION}'${C_NC} follows the expected basic ${C_BOLD}'vNN.NN.NN[optional]'${C_NC} pattern." ok 1

		declare -A version_components
		version_components['major']=${BASH_REMATCH[1]}
		version_components['minor']=${BASH_REMATCH[2]}
		version_components['patch']=${BASH_REMATCH[3]}
		version_components['optional']=${BASH_REMATCH[4]}
	else
		bme_log "BME version ${C_BOLD}'${BME_VERSION}'${C_NC} doesn't match expected pattern ${C_BOLD}'vNN.NN.NN[optional]'${C_NC}." fail 1
		return 1
	fi

# As per Semantic version standard, "patch" level (defined as an integer), may be followed by a pre-release (-[something]) or build metadata (+[something]) suffix
	if [[ -n ${version_components['optional']} ]]; then
		if ! [[ ${version_components['optional']} =~ ^[-\+]([[:alnum:]]|\.|\-)+$ ]]; then
			err_msg="Optional patch extension ${C_BOLD}'${version_components['optional']}'${C_NC} doesn't match expected pattern.\n"
			err_msg+="\tFull version: ${C_BOLD}'${BME_VERSION}'${C_NC}."
			bme_log "${err_msg}" fail 1
			exit 1
		else
			bme_log "Optional patch extension ${C_BOLD}'${version_components['optional']}'${C_NC} matches de expected pattern." ok 1
		fi
	else
		bme_log "Version '${C_BOLD}'${BME_VERSION}'${C_NC}' doesn't have optional patch extension." info 1
	fi

	bme_log "Check ${C_BOLD}'BME version formatting'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
}


#--
# EVALUATES bme_check_version()
#--
check_test_version_function() {
# Testing old version
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
	BME_VERSION='vasdf'
	local function_output=$(bme_check_version)
	local stripped_output=$(strip_escape_codes "${function_output}")

	if [[ "${stripped_output}" =~ .*"version couldn't be found at your remote".* ]]; then
		bme_log "Check ${C_BOLD}'BME unknown version'${C_NC}." ok 1
	else
		bme_log "Check ${C_BOLD}'BME older version'${C_NC}." fail 1
		bme_log "${C_BOLD}bme_check_version() output follows:${C_NC}"
		bme_log "${function_output}" '' 1
		bme_log "${C_BOLD}end of bme_check_version() output.${C_NC}"
		return 1
	fi
}

main; exit $?
