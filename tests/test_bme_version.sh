#!/usr/bin/env bash

# Meant to be run from maketests.sh.  See its exported variables

# TESTS BME_VERSION value and evaluation

#--
# EVALUATES CURRENT VERSION
#--
# Version should match 'v[number].[number].[number][optional]'
# ...where [optional] starts with '+' or '-', plus an alphanumeric string with dots or hypens.
# See: https://semver.org/
source "${BUILD_DIR}/${SCRIPT}.version"
if ! [[ -n ${BME_VERSION} ]]; then
	echo "ERROR: 'BME_VERSION' undefined!"
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
	echo "ERROR: BME VERSION '${BME_VERSION}' DOESN'T MATCH EXPECTED PATTERN 'vNN.NN.NN[optional]'."
	echo -e "\tGOT '${BME_VERSION}'."
fi

# As per Semantic version standard, "patch" level (defined as an integer), may be followed by a pre-release (-[something]) or build metadata (+[something]) suffix
if [[ -n ${version_components['optional']} ]]; then
	if ! [[ ${version_components['optional']} =~ ^[-\+]([[:alnum:]]|\.|\-)+$ ]]; then
		echo "ERROR: optional patch extension doesn't meet expected pattern."
		echo -e "\tGOT '${version_components['optional']}'"
		echo -e "\tFULL VERSION: '${BME_VERSION}'"
		exit 1
	fi
fi

echo -e "Check 'BME version formatting': OK"

#--
# EVALUATES bme_check_version()
#--
source "${BUILD_DIR}/${SCRIPT}"
export DEBUG=$true
# Testing equality
export BME_VERSION=${VERSION}
function_output=$(bme_check_version)
stripped_output=$(strip_escape_codes "${function_output}")

if [[ "${stripped_output}" =~ .*"is up to date".* ]]; then
	echo -e "Check 'BME version equality': OK"
	unset function_output
else
	echo "Check 'BME version equality': FAIL"
	echo "OUTPUT:"
	echo -e "${function_output}"
	echo "END OF OUTPUT"
	exit 1
fi

# Testing old version
export BME_VERSION='v0.0.1'
function_output=$(bme_check_version)
stripped_output=$(strip_escape_codes "${function_output}")

if [[ "${stripped_output}" =~ .*"consider upgrading".* ]]; then
	echo -e "Check 'BME older version': OK"
	unset function_output
else
	echo "Check 'BME older version': FAIL"
	echo "OUTPUT:"
	echo -e "${function_output}"
	echo "END OF OUTPUT"
	exit 1
fi

# Testing unknown version
export BME_VERSION='vasdf'
function_output=$(bme_check_version)
stripped_output=$(strip_escape_codes "${function_output}")

if [[ "${stripped_output}" =~ .*"version couldn't be found at your remote".* ]]; then
	echo -e "Check 'BME unknown version': OK"
else
	echo "Check 'BME unknown version': FAIL"
	echo "OUTPUT:"
	echo -e "${function_output}"
	echo "END OF OUTPUT"
	exit 1
fi
