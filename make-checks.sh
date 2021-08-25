#!/bin/bash

#--
# FUNCTIONS
#--
# Checks Bash >= 5
check_bash_version() {
	if [ "${BASH_VERSINFO:-0}" -ge 5 ]; then
		echo -e "${C_BOLD}*${C_NC} Bash version ${C_GREEN}OK${C_NC}: ${BASH_VERSION}."
	else
		echo -e "${C_BOLD}*${C_NC} ${C_RED}ERROR:${C_NC} ${C_BOLD}BASH VERSION ERROR${C_NC}."
		echo -e "\tYour Bash version should be ${C_BOLD}5 or higher${C_NC}: ${BASH_VERSION}."
		error_dependencies=true
	fi
}


# Checks if ~/bin exists
check_bin() {
	if [ ! -d ~/bin ]; then
		echo -e "${C_BOLD}*${C_NC} ${C_YELLOW}WARNING:${C_NC} ${C_BOLD}'~/bin'${C_NC} doesn't exist."
		echo -en "\tDo you want me to create it? [y/N] " && read ans && [ ${ans:-N} = y ]
		case "$ans" in
			[yY])
				echo -en "\tCreating bin dir... "
				mkdir --mode=0750 ~/bin
				if [ $? -eq 0 ]; then
					echo -e "${C_GREEN}OK${C_NC}"
				else
					echo -e "\t${C_RED}FAIL${C_NC}"
					error_dependencies=true
				fi
			;;
			*)
				echo -e "${C_BOLD}NOT${C_NC} creating '~/bin' dir."
				error_dependencies=true
			;;
		esac
	else
		echo -e "${C_BOLD}*${C_NC} ${C_BOLD}~/bin${C_NC} exists: ${C_GREEN}OK${C_NC}"
	fi
}


# Checks if ~/bin is in path
check_bin_in_path() {
	if [[ "$PATH" =~ (^|:)"${HOME}/bin"(:|$) ]]; then
		echo -e "${C_BOLD}*${C_NC} ${C_BOLD}~/bin${C_NC} is in PATH: ${C_GREEN}OK${C_NC}"
	else
		echo -e "${C_BOLD}*${C_NC} ${C_RED}ERROR:${C_NC} ${C_BOLD}'~/bin'${C_NC} not in path. You need to add it."
		echo -e "\t${C_BOLD}CURRENT PATH:${C_NC} ${PATH}"
		error_dependencies=true
	fi
}


# Checks if virtualenvwrapper can be found
# This is not trivial, since "commands" are in fact sourced functions.
# It means they can't be found neither by `which` nor as commands, hash... in subshells
check_virtualenvwrapper() {
	if [ -n "${VIRTUALENVWRAPPER_SCRIPT}" ]; then
		echo -e "${C_BOLD}*${C_NC} ${C_BOLD}'virtualenvwrapper'${C_NC} found: ${C_GREEN}OK${C_NC}"
		echo -e "\tSourced from ${C_BOLD}'${VIRTUALENVWRAPPER_SCRIPT}'${C_NC}."
	else
		echo -e "${C_BOLD}*${C_NC} ${C_YELLOW}WARNING:${C_NC} ${C_BOLD}'virtualenvwrapper'${C_NC} couldn't be found."
		echo -e "\tYou won't be able to use Python virtualenv-related features."
		warning_dependencies=true
	fi
}

# Checks for md5sum
check_md5sum() {
	if md5sum --version > /dev/null 2>&1; then
		echo -e "${C_BOLD}*${C_NC} ${C_BOLD}'md5sum'${C_NC} found: ${C_GREEN}OK${C_NC}"
	else
		echo -e "${C_BOLD}*${C_NC} ${C_YELLOW}WARNING:${C_NC} ${C_BOLD}'md5sum'${C_NC} couldn't be found."
		echo -e "\tYou won't be able to use Python virtualenv-related features."
		echo -e "\tYou should install your system's ${C_BOLD}'coreutils'${C_NC} package."
		warning_dependencies=true
	fi
}

# Checks for jq
check_jq() {
	if jq --version > /dev/null 2>&1; then
		echo -e "${C_BOLD}*${C_NC} ${C_BOLD}'jq'${C_NC} found: ${C_GREEN}OK${C_NC}"
	else
		echo -e "${C_BOLD}*${C_NC} ${C_YELLOW}WARNING:${C_NC} ${C_BOLD}'jq'${C_NC} couldn't be found."
		echo -e "\tYou won't be able to use AWS-related features."
		echo -e "\tYou should install your system's ${C_BOLD}'jq'${C_NC} package."
		warning_dependencies=true
	fi
}



#--
# MAIN ENTRY POINT
#--
check_bash_version
check_bin
check_bin_in_path
check_virtualenvwrapper
check_md5sum
check_jq

# Check overall results
if [ true == "${warning_dependencies}" ]; then
	echo -e "\n${C_YELLOW}WARNING:${C_NC} Some non-critical dependencies unmet.  See above."
elif [ true == "${error_dependencies}" ]; then
	echo -e "\n${C_RED}ERROR:${C_NC} Unmet dependencies.  See above."
	exit 1
else
	echo -e "\n${C_BOLD}ALL CHECKS:${C_NC} ${C_GREEN}PASSED${C_NC}."
fi