# Meant to be sourced from main BME script
# Version-related operations

# "public" functions:
# __bme_check_version() - callable from bme_check_version()
#	Compares local BME version against remote git tags
#
# __bme_version_assert() - callable from bme_version_assert()
#	Allows comparing installed BME version against an arbitrary one
#	i.e.: assert project's module's version dependencies
# 1st param: 'version_operator': the evaluation to be done, i.e.: '>', '==', '>=', etc.
# RETURNS:
# 0: comparision is met
# 1: assertion is NOT met
# 2: wrong/unparseable comparision string
# >2: internal error


# Compares local BME version against remote git tags
__bme_check_version() {

# "pseudo private" function protection
	if [ "${FUNCNAME[1]}" != 'bme_check_version' ]; then
		local err_msg="${C_RED}INTERNAL ERROR:${C_NC} "
		err_msg+="Function ${C_BOLD}'${FUNCNAME[0]}()'${C_NC} is ${C_BOLD}private${C_NC}.  "
		err_msg+="You shouldn't invoke it from ${C_BOLD}'${FUNCNAME[1]}()${C_NC}!"
		>&2 bme_log "${err_msg}" error
		__version_clean
		return 1
	fi

# Gets the sorted list of remote tags
	local remote_tags=(`git ls-remote --refs --tags --sort -version:refname "${BME_REMOTE_GIT}" | cut --delimiter='/' --fields=3`)
	__bme_debug "${FUNCNAME[0]}: REMOTE TAGS: '${remote_tags[@]}'"
# then, get the last one (which should be the highest by "version name").
	local highest_tag="${remote_tags[0]}"

# Shows version comparation results
	if [ "${BME_VERSION}" == "${highest_tag}" ]; then
		bme_log "${C_BOLD}'Bash Magic Enviro'${C_NC} is up to date: ${C_BOLD}'${BME_VERSION}'${C_NC}." info 0
	elif [[ " ${remote_tags[*]} " =~ " ${BME_VERSION} " ]]; then
	# Our current version is found in the list of remote tags but, since it's not the highest one, it must be lower
		local log_msg="New ${C_BOLD}'Bash Magic Enviro'${C_NC} version available.  Please, consider upgrading.\n"
			log_msg+="\tYour local version: ${C_BOLD}'${BME_VERSION}'${C_NC}.\n"
			log_msg+="\tHighest version at ${C_BOLD}'${BME_REMOTE_GIT}'${C_NC}: ${C_BOLD}'${highest_tag}'${C_NC}."
		bme_log "${log_msg}" info 0
	else
	# Weird: local version not found at remote
		local log_msg="Your current ${C_BOLD}'Bash Magic Enviro'${C_NC} version couldn't be found at your remote.\n"
			log_msg+="\tYour local version: ${C_BOLD}'${BME_VERSION}'${C_NC}.\n"
			log_msg+="\tHighest version at ${C_BOLD}'${BME_REMOTE_GIT}'${C_NC}: ${C_BOLD}'${highest_tag}'${C_NC}."
		bme_log "${log_msg}" warning 0
	fi

# Clean after myself
	__version_clean
}


# Asserts BME version against currently installed one
# 1st param: 'version_operator': the evaluation to be done, i.e.: '>1.2', '==1.2.3', '>=3', etc.
# RETURNS:
# 0: comparision is met
# 1: assertion is NOT met
# 2: wrong/unparseable comparision string
# >2: internal error
__bme_version_assert() {
local version_operator="${@}"

# Params debug
	__bme_debug "${FUNCNAME[0]}: requested match: '${version_operator}'"
	version_operator="${version_operator//[[:space:]]/}"  # strip **all** whitespace
	__bme_debug "${FUNCNAME[0]}: requested match after whitespace prunning: '${version_operator}'"

# "pseudo private" function protection
	if [ "${FUNCNAME[1]}" != 'bme_version_assert' ]; then
		local err_msg="${C_RED}INTERNAL ERROR:${C_NC} "
		err_msg+="Function ${C_BOLD}'${FUNCNAME[0]}()'${C_NC} is ${C_BOLD}private${C_NC}.  "
		err_msg+="You shouldn't invoke it from ${C_BOLD}'${FUNCNAME[1]}()${C_NC}!"
		>&2 bme_log "${err_msg}" error
		__version_clean
		return 1
	fi

# No parameters.  Show help instead
	if (( $# == 0 )); then
		__bme_version_assert_help
		__version_clean; return 0
	fi

# Sets apart operator from version string
	if [[ "${version_operator}" =~ ^('=='|'!='|'>='|'<='|'>'|'<')(.+) ]] ; then
		local operator="${BASH_REMATCH[1]}"
		if [ -n "${BASH_REMATCH[2]}" ]; then
			local matching_version="${BASH_REMATCH[2]}"
			matching_version="${matching_version#[v|V]}" # drops optional 'v'
		else
			local err_msg="while processing version operator ${C_BOLD}'${version_operator}'${C_NC}: matching version couldn't be extracted.\n"
			bme_log "${err_msg}" error
			__bme_version_assert_help
			__version_clean; return 2
		fi

		__bme_debug "${FUNCNAME[0]}: operator: '${operator}'; version: '${matching_version}'"
	else
		bme_log "Version operator ${C_BOLD}'${version_operator}'${C_NC} didn't match the expected format.\n" error
		__bme_version_assert_help
		__version_clean; return 2
	fi

# Requested version string into dictionary
	declare -A requested_version_dict
	# major
	if [[ "${matching_version}" =~ ^([0-9]+)(\.?)(.*) ]]; then
		requested_version_dict['major']="${BASH_REMATCH[1]}"
		__bme_debug "${FUNCNAME[0]}: major version: '${requested_version_dict['major']}'"
		#${BASH_REMATCH[2]} - optional dot: drop
		if [ -n "${BASH_REMATCH[3]}" ]; then
			local remainder="${BASH_REMATCH[3]}"
			__bme_debug "${FUNCNAME[0]}: remainder after major: '${remainder}'"
		else
			__bme_debug "${FUNCNAME[0]}: no remainder after major."
		fi
	else
		local err_msg="while processing version operator ${C_BOLD}'${version_operator}'${C_NC}, version string doesn't match expected pattern:\n"
		err_msg+="* version operator: ${C_BOLD}'${operator}'${C_NC}.\n"
		err_msg+="* version string: ${C_RED}'${matching_version}'${C_NC}.\n"

		bme_log "${err_msg}" error
		__bme_version_assert_help
		__version_clean; return 2
	fi
	# minor
	if [ -n "${remainder}" ]; then
		if [[ "${remainder}" =~ ^([0-9]+)(\.?)(.*) ]]; then
			requested_version_dict['minor']="${BASH_REMATCH[1]}"
			__bme_debug "${FUNCNAME[0]}: minor version: '${requested_version_dict['minor']}'"
			#${BASH_REMATCH[2]} - optional dot: drop
			if [ -n "${BASH_REMATCH[3]}" ]; then
				remainder="${BASH_REMATCH[3]}"
				__bme_debug "${FUNCNAME[0]}: remainder after minor: '${remainder}'"
			else
				__bme_debug "${FUNCNAME[0]}: no remainder after minor."
				unset remainder
			fi
		else
			local err_msg="while processing version operator ${C_BOLD}'${version_operator}'${C_NC}, version string doesn't match expected pattern:\n"
			err_msg+="* version operator: ${C_BOLD}'${operator}'${C_NC}.\n"
			err_msg+="* major version: ${C_BOLD}'${requested_version_dict['major']}'${C_NC}.\n"
			err_msg+="* remainder: ${C_RED}'${remainder}'${C_NC}.\n"

			bme_log "${err_msg}" error
			__bme_version_assert_help
			__version_clean; return 2
		fi
	fi
	# patch level
	if [ -n "${remainder}" ]; then
		if [[ "${remainder}" =~ ^([0-9]+)(-*)(.*) ]]; then
			requested_version_dict['patch']="${BASH_REMATCH[1]}"
			__bme_debug "${FUNCNAME[0]}: patch version: '${requested_version_dict['patch']}'"
			if [ -n "${BASH_REMATCH[2]}" ]; then
			# There is a pre-release link, therefore there must be a pre-release
				if [ -n "${BASH_REMATCH[3]}" ]; then
					requested_version_dict['pre-release']="${BASH_REMATCH[3]}"
					__bme_debug "${FUNCNAME[0]}: pre-release: '${requested_version_dict['pre-release']}'.  Process ends here"
					unset remainder
				else
					local err_msg="while processing version operator ${C_BOLD}'${version_operator}'${C_NC}, version string doesn't match expected pattern:\n"
					err_msg+="* version operator: ${C_BOLD}'${operator}'${C_NC}.\n"
					err_msg+="* major version: ${C_BOLD}'${requested_version_dict['major']}'${C_NC}.\n"
					err_msg+="* minor version: ${C_BOLD}'${requested_version_dict['minor']}'${C_NC}.\n"
					err_msg+="* patch version: ${C_BOLD}'${requested_version_dict['patch']}'${C_NC}.\n"
					err_msg+="* expecting a pre-release token after ${C_RED}'${BASH_REMATCH[2]}'${C_NC}.\n"

					bme_log "${err_msg}" error
					__bme_version_assert_help
					__version_clean; return 2
				fi
			elif [ -n "${BASH_REMATCH[3]}" ]; then
			# if there's no ${BASH_REMATCH[2]}, then ${BASH_REMATCH[3]} should be empty
				local err_msg="while processing version operator ${C_BOLD}'${version_operator}'${C_NC}, version string doesn't match expected pattern:\n"
				err_msg+="* version operator: ${C_BOLD}'${operator}'${C_NC}.\n"
				err_msg+="* major version: ${C_BOLD}'${requested_version_dict['major']}'${C_NC}.\n"
				err_msg+="* minor version: ${C_BOLD}'${requested_version_dict['minor']}'${C_NC}.\n"
				err_msg+="* patch version: ${C_BOLD}'${requested_version_dict['patch']}'${C_NC}.\n"
				err_msg+="* wrong pre-release token ${C_RED}'${BASH_REMATCH[3]}'${C_NC}.\n"

				bme_log "${err_msg}" error
				__bme_version_assert_help
				__version_clean; return 2
			else
				__bme_debug "${FUNCNAME[0]}: no pre-release.  Process ends here"
				unset remainder
			fi
		else
			local err_msg="while processing version operator ${C_BOLD}'${version_operator}'${C_NC}, version string doesn't match expected pattern:\n"
			err_msg+="* version operator: ${C_BOLD}'${operator}'${C_NC}.\n"
			err_msg+="* major version: ${C_BOLD}'${requested_version_dict['major']}'${C_NC}.\n"
			err_msg+="* minor version: ${C_BOLD}'${requested_version_dict['minor']}'${C_NC}.\n"
			err_msg+="* remainder: ${C_RED}'${remainder}'${C_NC}.\n"

			bme_log "${err_msg}" error
			__bme_version_assert_help
			__version_clean; return 2
		fi
	fi
	unset remainder
	# Show matching version dictionary results
	local matching_version_dict_msg="${FUNCNAME[0]}: version to match:\n"
	for key in 'major' 'minor' 'patch' 'pre-release'; do
		matching_version_dict_msg+="* ${key}: '${requested_version_dict[${key}]}'\n"
	done
	__bme_debug "${matching_version_dict_msg}"
	unset key

# Requested BME_VERSION into dictionary
	__bme_debug "Current BME_VERSION is '${BME_VERSION}'"
	[ -n "${BME_VERSION}" ] || {
		local err_msg="${C_BOLD}${FUNCNAME[0]}():${C_NC} BME_VERSION not set.  This is an internal error."
		bme_log "${err_msg}" fatal
		__version_clean; return 3
	}
	declare -A current_version_dict
	local current_version="${BME_VERSION#[v|V]}" # drops optional 'v'
	# major
	if [[ "${current_version}" =~ ^([0-9]+)(\.?)(.*) ]]; then
		current_version_dict['major']="${BASH_REMATCH[1]}"
		__bme_debug "${FUNCNAME[0]}: current version - major: '${current_version_dict['major']}'"
		#${BASH_REMATCH[2]} - optional dot: drop
		if [ -n "${BASH_REMATCH[3]}" ]; then
			local remainder="${BASH_REMATCH[3]}"
			__bme_debug "${FUNCNAME[0]}: remainder after major: '${remainder}'"
		else
			__bme_debug "${FUNCNAME[0]}: no remainder after major."
		fi
	else
		local err_msg="while processing BME_VERSION ${C_BOLD}'${BME_VERSION}'${C_NC}, version string doesn't match expected pattern:\n"
		err_msg+="* version string: ${C_RED}'${current_version}'${C_NC}.\n"

		bme_log "${err_msg}" error
		__version_clean; return 3
	fi
	# minor
	if [ -n "${remainder}" ]; then
		if [[ "${remainder}" =~ ^([0-9]+)(\.?)(.*) ]]; then
			current_version_dict['minor']="${BASH_REMATCH[1]}"
			__bme_debug "${FUNCNAME[0]}: minor version: '${requested_version_dict['minor']}'"
			#${BASH_REMATCH[2]} - optional dot: drop
			if [ -n "${BASH_REMATCH[3]}" ]; then
				remainder="${BASH_REMATCH[3]}"
				__bme_debug "${FUNCNAME[0]}: remainder after minor: '${remainder}'"
			else
				__bme_debug "${FUNCNAME[0]}: no remainder after minor."
				unset remainder
			fi
		else
			local err_msg="while processing BME_VERSION ${C_BOLD}'${BME_VERSION}'${C_NC}, version string doesn't match expected pattern:\n"
			err_msg+="* current version: ${C_BOLD}'${current_version}'${C_NC}.\n"
			err_msg+="* major version: ${C_BOLD}'${current_version_dict['major']}'${C_NC}.\n"
			err_msg+="* remainder: ${C_RED}'${remainder}'${C_NC}.\n"

			bme_log "${err_msg}" error
			__bme_version_assert_help
			__version_clean; return 3
		fi
	fi
	# patch level
	if [ -n "${remainder}" ]; then
		if [[ "${remainder}" =~ ^([0-9]+)(-*)(.*) ]]; then
			current_version_dict['patch']="${BASH_REMATCH[1]}"
			__bme_debug "${FUNCNAME[0]}: patch version: '${current_version_dict['patch']}'"
			if [ -n "${BASH_REMATCH[2]}" ]; then
			# There is a pre-release link, therefore there must be a pre-release
				if [ -n "${BASH_REMATCH[3]}" ]; then
					current_version_dict['pre-release']="${BASH_REMATCH[3]}"
					__bme_debug "${FUNCNAME[0]}: pre-release: '${current_version_dict['pre-release']}'.  Process ends here"
					unset remainder
				else
					local err_msg="while processing current version ${C_BOLD}'${current_version}'${C_NC}, version string doesn't match expected pattern:\n"
					err_msg+="* current version: ${C_BOLD}'${current_version}'${C_NC}.\n"
					err_msg+="* major version: ${C_BOLD}'${current_version_dict['major']}'${C_NC}.\n"
					err_msg+="* minor version: ${C_BOLD}'${current_version_dict['minor']}'${C_NC}.\n"
					err_msg+="* patch version: ${C_BOLD}'${current_version_dict['patch']}'${C_NC}.\n"
					err_msg+="* expecting a pre-release token after ${C_RED}'${BASH_REMATCH[2]}'${C_NC}.\n"

					bme_log "${err_msg}" error
					__bme_version_assert_help
					__version_clean; return 2
				fi
			elif [ -n "${BASH_REMATCH[3]}" ]; then
			# if there's no ${BASH_REMATCH[2]}, then ${BASH_REMATCH[3]} should be empty
				local err_msg="while processing current version ${C_BOLD}'${vcurrent_version}'${C_NC}, version string doesn't match expected pattern:\n"
				err_msg+="* current version: ${C_BOLD}'${current_version}'${C_NC}.\n"
				err_msg+="* major version: ${C_BOLD}'${current_version_dict['major']}'${C_NC}.\n"
				err_msg+="* minor version: ${C_BOLD}'${current_version_dict['minor']}'${C_NC}.\n"
				err_msg+="* patch version: ${C_BOLD}'${current_version_dict['patch']}'${C_NC}.\n"
				err_msg+="* wrong pre-release token ${C_RED}'${BASH_REMATCH[3]}'${C_NC}.\n"

				bme_log "${err_msg}" error
				__bme_version_assert_help
				__version_clean; return 2
			else
				__bme_debug "${FUNCNAME[0]}: no pre-release.  Process ends here"
				unset remainder
			fi
		else
			local err_msg="while processing version operator ${C_BOLD}'${version_operator}'${C_NC}, version string doesn't match expected pattern:\n"
			err_msg+="* version operator: ${C_BOLD}'${operator}'${C_NC}.\n"
			err_msg+="* major version: ${C_BOLD}'${requested_version_dict['major']}'${C_NC}.\n"
			err_msg+="* minor version: ${C_BOLD}'${requested_version_dict['minor']}'${C_NC}.\n"
			err_msg+="* remainder: ${C_RED}'${remainder}'${C_NC}.\n"

			bme_log "${err_msg}" error
			__bme_version_assert_help
			__version_clean; return 2
		fi
	fi
	unset remainder
	# Show current version dictionary results
	local current_version_dict_msg="${FUNCNAME[0]}: current version:\n"
	for key in 'major' 'minor' 'patch' 'pre-release'; do
		current_version_dict_msg+="* ${key}: '${current_version_dict[${key}]}'\n"
	done
	__bme_debug "${current_version_dict_msg}"
	unset key

# BME_VERSION comparision against requested match
	__bme_debug "ABOUT TO COMPARE CURRENT '${current_version}' '${operator}' DESIRED '${matching_version}'"
	local current_padded requested_padded
	for key in 'major' 'minor' 'patch'; do
		if [ -n "${requested_version_dict[${key}]}" ]; then
			__bme_debug "Requested '${key}' is '${requested_version_dict[${key}]}'"

			current_padded+=$(printf "%03d\n" "${current_version_dict[${key}]}")
			requested_padded+=$(printf "%03d\n" "$((10#${requested_version_dict[${key}]}))")
		else
			__bme_debug "Requested '${key}' is UNSET.'"
			current_padded+=$(printf "%03d\n" "${requested_version_dict[${key}]}")
			requested_padded+=$(printf "%03d\n" "${requested_version_dict[${key}]}")
		fi
	done
	# the comparision itself
	__bme_debug "OPERATION: '${current_padded}' ('${current_version}') '${operator}' '${requested_padded}' ('${matching_version}')"
	if (( 10#${current_padded} ${operator} 10#${requested_padded} )); then
		__bme_debug "'${current_padded}' is '${operator}' '${requested_padded}'"
		bme_log "current BME version ${C_BOLD}'${BME_VERSION}'${C_NC} matches ${C_BOLD}'${version_operator}'${C_NC} request." info
		return 0
	else
		__bme_debug "'${current_padded}' is NOT '${operator}' '${requested_padded}'" info
		bme_log "Current BME version ${C_BOLD}'${BME_VERSION}'${C_NC} does ${C_BOLD}NOT${C_NC} match ${C_BOLD}'${version_operator}'${C_NC} request." warning
		return 1
	fi

# Clean after myself
	__version_clean
}


# bme_version_assert() help
__bme_version_assert_help() {
		local help_msg="${C_BOLD}bme_version_assert${C_NC} ['comparision string']\n"
		help_msg+="${C_BOLD}bme_version_assert()${C_NC} helps you asserting your dependencies against installed BME version.\n"
		help_msg+="\n${C_BOLD}Comparision string format:${C_NC}\n"
		help_msg+="${C_BOLD}* version operators:${C_NC} '>', '<', '==', '!=', '>=', '<='.\n"
		help_msg+="${C_BOLD}* version string format:${C_NC} '(v)[major](.)[minor](.)[patch](-)[pre-release]\n"
		help_msg+="\n${C_BOLD}return codes:${C_NC}\n"
		help_msg+="${C_BOLD}* 0:${C_NC} BME version meets the condition.\n"
		help_msg+="${C_BOLD}* 1:${C_NC} BME version does ${C_BOLD}not${C_NC} meet the condition.\n"
		help_msg+="${C_BOLD}* 2:${C_NC} wrong/unparseable comparision string.\n"
		help_msg+="${C_BOLD}* other values:${C_NC} unmanaged error.\n"
		help_msg+="\n${C_BOLD}examples:${C_NC}\n"
		help_msg+="${C_BOLD}*${C_NC} bme_version_assert '>1.2'\n"
		help_msg+="${C_BOLD}*${C_NC} bme_version_assert '==1'\n"
		help_msg+="${C_BOLD}*${C_NC} bme_version_assert '!=1.2.3-patch1'\n"
		help_msg+="\n"

# TODO: expected final specification
# 		help_msg+="${C_BOLD}example:${C_NC} bme_version_assert '(>1.2 && <=1.2.5) || >=1.3'\n\n"
# 		help_msg+="${C_BOLD}Comparision string format:${C_NC}\n"
# 		help_msg+="${C_BOLD}* boolean ligatures:${C_NC} '&&', '||'.\n"
# 		help_msg+="${C_BOLD}*${C_NC} parenthesis '(', ')' can be used to set precedende.\n\n"
#
		bme_log "${help_msg}" function
}


# Cleans whatever is loaded on this file
__version_clean() {

	unset -f __bme_check_version
	unset -f __bme_version_assert
	unset -f __bme_version_assert_help
	unset -f __version_clean
}

