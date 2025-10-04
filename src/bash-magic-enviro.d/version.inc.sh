# Meant to be sourced from main BME script
# Version-related operations

# "public" functions:
# __bme_check_version() - callable from bme_check_version()
#	Compares local BME version against remote git tags

# Compares local BME version against remote git tags
__bme_check_version() {

# "pseudo private" function protection
	if [ "${FUNCNAME[1]}" != 'bme_check_version' ]; then
		local err_msg="${C_RED}INTERNAL ERROR:${C_NC} "
		err_msg+="Function ${C_BOLD}'${FUNCNAME[0]}()'${C_NC} is ${C_BOLD}private${C_NC}.  "
		err_msg+="You shouldn't invoke it from ${C_BOLD}'${FUNCNAME[1]}()${C_NC}!"
		>&2 bme_log "${err_msg}" error
		unset -f __bme_check_version
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
	unset -f __bme_check_version
}
