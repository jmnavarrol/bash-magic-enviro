#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests BME_VERSION format and value

function main() {
	source bash-magic-enviro || exit $?
	check_version_format || exit $?
	check_test_version_function || exit $?
	check_version_assert_format || exit $?
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
	local BME_VERSION='v0.0.1'
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
	local BME_VERSION='vasdf'
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
# Validates the comparision string format
check_version_assert_format() {
local invalid_format_rc=2

local valid_operators=(
	'=='
	'!='
	'>='
	'<='
	'>'
	'<'
)
local invalid_operators=(
	''
	'!>'
	'asdf'
	'1'
)

local valid_versions=(
	'1'
	'1.'
	'1.2'
	'1.2.'
	'1.2.3'
	'1.2.3-dev1'
)
local invalid_versions=(
	''
	'a'
	'1a'
	'a1'
	'1a.'
	'a1.'
	'1.a'
	'1.1a'
	'1.2.3-'
	'1.2.3dev1'
	'1.2.3+dev1'
)

	test_title "assert version request operator"

	for operator in "${valid_operators[@]}"; do
		for version in "${valid_versions[@]}"; do
			local random_padding=$((0 + $RANDOM % 3))
			local padding=''
			for ((i = 0; i < $random_padding; ++i)); do
				padding+=' '
			done
			unset i

			local version_operator="${padding}${operator}${padding}${version}${padding}"
			version_assert=$(bme_version_assert ${version_operator})
			local rc=$?
			if (( rc >= $invalid_format_rc )); then
				local err_msg="while testing valid version operator '${BME_VERSION}${version_operator}': expected rc is >= '${invalid_format_rc}', got '$rc'\n"
				err_msg+="${version_assert}"
				test_log "$err_msg" fail
				return $rc
			fi
		done
		for version in "${invalid_versions[@]}"; do
			local random_padding=$((0 + $RANDOM % 3))
			local padding=''
			for ((i = 0; i < $random_padding; ++i)); do
				padding+=' '
			done
			unset i

			local version_operator="${padding}${operator}${padding}${version}${padding}"
			version_assert=$(bme_version_assert ${version_operator})
			local rc=$?
			if (( rc != $invalid_format_rc )); then
				local err_msg="while testing invalid version operator '${version_operator}': expected rc is '${invalid_format_rc}', got '$rc'\n"
				err_msg+="${version_assert}"
				test_log "$err_msg" fail
				return $rc
			fi
		done
	done
	unset operator

	for operator in "${invalid_operators[@]}"; do
		for version in "${valid_versions[@]}"; do
			local random_padding=$((0 + $RANDOM % 3))
			local padding=''
			for ((i = 0; i < $random_padding; ++i)); do
				padding+=' '
			done
			unset i

			local version_operator="${padding}${operator}${padding}${version}${padding}"
			version_assert=$(bme_version_assert ${version_operator})
			local rc=$?
			if (( rc != $invalid_format_rc )); then
				local err_msg="while testing valid version operator '${version_operator}': expected rc is '${expected_rc}', got '$rc'\n"
				err_msg+="${version_assert}"
				test_log "$err_msg" fail
				return $rc
			fi
		done
		for version in "${invalid_versions[@]}"; do
			local random_padding=$((0 + $RANDOM % 3))
			local padding=''
			for ((i = 0; i < $random_padding; ++i)); do
				padding+=' '
			done
			unset i

			local version_operator="${padding}${operator}${padding}${version}${padding}"
			# invalid x invalid may end up requesting an empty string, which is valid (only it shows help)
			if [ -n "${version_operator// }" ]; then
				version_assert=$(bme_version_assert ${version_operator})
				local rc=$?
				if (( rc != $invalid_format_rc )); then
					local err_msg="while testing invalid version operator '${version_operator}': expected rc is '${invalid_format_rc}', got '$rc'\n"
					err_msg+="${version_assert}"
					test_log "$err_msg" fail
					return $rc
				fi
			fi
		done
	done
	unset operator

	test_log "Check ${C_BOLD}'bme_version_assert()'${C_NC} function: ${C_GREEN}OK${C_NC}" info
}

# Asserts the requested comparision itself
check_version_assert() {
local BME_VERSION='v1.10.2-dev1'
local equal_versions=(
	'1' 'v1'
	'1.10' 'v1.10'
	'1.10.2' 'v1.10.2'
	'1.10.2-dev1' 'v1.10.2-dev1'
	'1.10.2-other' 'v1.10.2-other'
)
local less_than_versions=(
	'0' 'v0'
	'1.9' 'v1.9'
	'1.09' 'v1.09'
	'1.10.1' 'v1.10.1'
	'1.10.1-dev2' 'v1.10.1-dev2'
)
local greater_than_versions=(
	'2' 'v2'
	'1.11' 'v1.11'
	'1.10.3' 'v1.10.3'
	'1.10.03' 'v1.10.03'
)
declare -A valid_operators=(
	'=='
	'!='
	'>='
	'<='
	'>'
	'<'
)

	test_title "assert version comparisions"

	local expected_rc=''
	local got_rc=''

	for version in "${equal_versions[@]}"; do
		expected_rc=0
		for comparator in '==' '>=' '<='; do
			bme_version_assert "${comparator}${version}"
			got_rc=$?
			if (( $got_rc != $expected_rc )); then
				local err_msg="while equal-like testing '${BME_VERSION} ${comparator} ${version}'': "
				err_msg+="expected rc is '${expected_rc}', got '$got_rc'.\n"
				test_log "$err_msg" fail
				return 1
			fi
		done

		expected_rc=1
		for comparator in '>' '<'; do
			bme_version_assert "${comparator}${version}"
			got_rc=$?
			if (( $got_rc != $expected_rc )); then
				local err_msg="while unequal-like testing '${BME_VERSION} ${comparator} ${version}'': "
				err_msg+="expected rc is '${expected_rc}', got '$got_rc'-\n"
				test_log "$err_msg" fail
				return 1
			fi
		done
	done

	for version in "${less_than_versions[@]}"; do
		expected_rc=0
		for comparator in '!=' '>=' '>'; do
			bme_version_assert "${comparator}${version}"
			got_rc=$?
			if (( $got_rc != $expected_rc )); then
				local err_msg="while less-than testing '${BME_VERSION} ${comparator} ${version}' (true): "
				err_msg+="expected rc is '${expected_rc}', got '$got_rc'.\n"
				test_log "$err_msg" fail
				return 1
			fi
		done

		expected_rc=1
		for comparator in  '==' '<=' '<'; do
			bme_version_assert "${comparator}${version}"
			got_rc=$?
			if (( $got_rc != $expected_rc )); then
				local err_msg="while less-than testing '${BME_VERSION} ${comparator} ${version}' (false): "
				err_msg+="expected rc is '${expected_rc}', got '$got_rc'-\n"
				test_log "$err_msg" fail
				return 1
			fi
		done
	done


	for version in "${greater_than_versions[@]}"; do
		expected_rc=0
		for comparator in '!=' '<=' '<'; do
			bme_version_assert "${comparator}${version}"
			got_rc=$?
			if (( $got_rc != $expected_rc )); then
				local err_msg="while greater-than testing '${BME_VERSION} ${comparator} ${version}' (true): "
				err_msg+="expected rc is '${expected_rc}', got '$got_rc'.\n"
				test_log "$err_msg" fail
				return 1
			fi
		done

		expected_rc=1
		for comparator in '==' '>=' '>'; do
			bme_version_assert "${comparator}${version}"
			got_rc=$?
			if (( $got_rc != $expected_rc )); then
				local err_msg="while less-than testing '${BME_VERSION} ${comparator} ${version}' (false): "
				err_msg+="expected rc is '${expected_rc}', got '$got_rc'-\n"
				test_log "$err_msg" fail
				return 1
			fi
		done
	done

# Clean after myself
	unset BME_VERSION version comparator
	test_log "Check ${C_BOLD}'check_version_assert()'${C_NC} function: ${C_GREEN}OK${C_NC}" info
}

main; exit $?
