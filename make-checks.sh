#!/usr/bin/env bash

main() {
	check_bash_version
	check_destdir_in_path
	check_os
	check_git_version
	check_virtualenv
	check_md5sum
	check_flock
	check_jq

# Check overall results
	if [ true == "${warning_dependencies}" ]; then
		echo -e "\n${C_YELLOW}WARNING:${C_NC} Some non-critical dependencies unmet.  See above."
	fi
	if [ true == "${error_dependencies}" ]; then
		echo -e "\n${C_RED}ERROR:${C_NC} Unmet dependencies: BME won't be installed.  See above."
		echo -e "\tPlease correct errors and retry."
		exit 1
	else
		echo -e "\n${C_BOLD}ALL CHECKS:${C_NC} ${C_GREEN}PASSED${C_NC}."
	fi
}

#--
# FUNCTIONS
#--
# Checks Bash >= 4
check_bash_version() {
	if [ "${BASH_VERSINFO:-0}" -ge 4 ]; then
		echo -e "${C_BOLD}* Bash version ${BASH_VERSION}${C_NC}: ${C_GREEN}OK${C_NC}"
	else
		echo -e "${C_BOLD}*${C_NC} ${C_RED}ERROR:${C_NC} ${C_BOLD}BASH VERSION ERROR${C_NC}."
		echo -e "\tYour Bash version should be ${C_BOLD}4 or higher${C_NC}: ${BASH_VERSION}."
		error_dependencies=true
	fi
}

# Checks if ${DESTDIR} is in path
check_destdir_in_path() {
	if [[ "$PATH" =~ (^|:)"${DESTDIR}"(:|$) ]]; then
		echo -e "${C_BOLD}*${C_NC} ${C_BOLD}'${DESTDIR}'${C_NC} is in PATH: ${C_GREEN}OK${C_NC}"
	else
		echo -e "${C_BOLD}*${C_NC} ${C_RED}ERROR:${C_NC} ${C_BOLD}'${DESTDIR}'${C_NC} not in path. You need to add it."
		echo -e "\t${C_BOLD}CURRENT PATH:${C_NC} ${PATH}"
		error_dependencies=true
	fi
}

# Checks OS-dependent nuances
check_os() {
	case "$OSTYPE" in
		darwin*)
			local os_msg="${C_BOLD}* MacOS detected ($OSTYPE)${C_NC}. "
			os_msg+="Checking GNU tooling..."
			echo -e "${os_msg}"
			check_macos || return $?
		;;
		linux*)
			local os_msg="${C_BOLD}* Linux detected ($OSTYPE)${C_NC}. "
			os_msg+="Follow on."
			echo -e "${os_msg}"
		;;
		*)
			local os_msg="Unmanaged OS ($OSTYPE)\n"
			os_msg+="\tLet's hope BME works OK. You may open an issue to check for support."
			echo -e "${os_msg}"
			warning_dependencies=true
		;;
	esac

# Final message
	if [ ! true == "${warning_dependencies}" ] && [ ! true == "${error_dependencies}" ]; then
		echo -e "${C_BOLD}* OS dependencies for '${OSTYPE}': ${C_GREEN}OK${C_NC}"
	fi
}

# Custom checks on macOS
check_macos() {
local -A gnu_tools=(
	['mkdir']='coreutils'
	['find']='findutils'
	['sed']='gnu-sed'
)
# common tools
	for gnu_tool in ${!gnu_tools[@]}; do
		${gnu_tool} --version > /dev/null 2>&1 || {
		# trying tool's "g-version" on macos
			if ! which g${gnu_tool} > /dev/null; then
				local err_msg="${C_RED}ERROR:${C_NC} while testing ${C_BOLD}'$OSTYPE'${C_NC}:\n"
				err_msg+="\tGNU tooling couldn't be found.\n"
				err_msg+="\tYou should install ${C_BOLD}'brew install ${gnu_tools[${gnu_tool}]}'${C_NC} and follow instructions to properly set ${C_BOLD}'\$PATH'${C_NC} environment variable."
			else
				local err_msg="${C_RED}ERROR:${C_NC} while testing ${C_BOLD}'$OSTYPE'${C_NC}:\n"
				err_msg+="\tit seems ${C_BOLD}'brew ${gnu_tools[${gnu_tool}]}'${C_NC} is installed but unconfigured.\n"
				err_msg+="\tyou need to propely set your ${C_BOLD}'\$PATH'${C_NC} environment variable."
			fi
			echo -e "${err_msg}"
			error_dependencies=true
		}
	done
# grep
	echo "HELLO!" | grep --perl-regex --only-matching "^HELLO!" > /dev/null 2>&1 || {
	# trying grep' "g-version" on macos
		if ! which ggrep > /dev/null; then
			local err_msg="${C_RED}ERROR:${C_NC} while testing ${C_BOLD}'$OSTYPE'${C_NC}:\n"
			err_msg+="\tGNU tooling couldn't be found.\n"
			err_msg+="\tYou should install ${C_BOLD}'brew install grep'${C_NC} and follow instructions to properly set '\$PATH' environment variable."
		else
			local err_msg="${C_RED}ERROR:${C_NC} while testing ${C_BOLD}'$OSTYPE'${C_NC}:\n"
			err_msg+="\tit seems ${C_BOLD}'brew grep'${C_NC} is installed but unconfigured.\n"
			err_msg+="\tyou need to propely set your '\$PATH' environment variable."
		fi
		echo -e "${err_msg}"
		error_dependencies=true
	}
}

# Checks Git >= 2.9
check_git_version() {
	if ! git version > /dev/null 2>&1; then
		echo -e "${C_RED}ERROR:${C_NC} ${C_BOLD}'git'${C_NC} couldn't be found. You should install it."
		error_dependencies=true
	else
		local git_version=(`git version`)
		      git_version="${git_version[2]}"
		local git_major="${git_version%%\.*}"
		local git_minor="${git_version#*\.}"
		      git_minor="${git_minor%%\.*}"

		local bad_git_version=true
		if [ "${git_major}" -ge 2 ]; then
			if [ "${git_minor}" -ge 9 ]; then
				bad_git_version=false
			fi
		fi

		if ($bad_git_version); then
			local log_msg="${C_YELLOW}WARNING:${C_NC} Detected git version ${C_BOLD}'${git_version}'${C_NC} is lower than required: ${C_BOLD}'2.9'${C_NC}.\n"
			log_msg+="\tPlease upgrade."
			echo -e "${log_msg}"
			warning_dependencies=true
		else
			echo -e "${C_BOLD}*${C_NC} ${C_BOLD}Git version ${git_version}${C_NC}: ${C_GREEN}OK${C_NC}"
		fi
	fi
}

# Tests the ability to create a Python virtualenv
check_virtualenv() {
# Check for Python3
	if which python3 > /dev/null; then
		local PYTHON_CMD=`which python3`
	elif which python > /dev/null; then
		if [[ $(python --version 2>&1) =~ 'Python 3' ]]; then
			local PYTHON_CMD=`which python`
		fi
	fi

	if [ -n "${PYTHON_CMD}" ]; then
		echo -e "${C_BOLD}* "`${PYTHON_CMD} --version`": ${C_GREEN}OK${C_NC}"
	else
		local err_msg="No valid Python3 version found.\n"
		err_msg+="\tYou won't be able to use Python virtualenv-related features."
		echo -e "${err_msg}"
		warning_dependencies=true
		return 1
	fi

# Check for virtualenv creation
	venv_output=$("${PYTHON_CMD}" -m venv .here) || {
		local rc_venv=$?
		local err_msg="${C_RED}ERROR${C_NC} (${rc_venv}): "
		err_msg+="${C_BOLD}Couldn't create a Python virtualenv:${C_NC}\n"
		err_msg+="\t'${PYTHON_CMD} -m venv .here'"
		err_msg+="\n${C_BOLD}OUTPUT FOLLOWS:${C_NC}\n"
		err_msg+="${venv_output}"
		echo -e "${err_msg}"
		warning_dependencies=true
		rm --recursive --force .here || {
			local rc_rm=$?
			local err_msg="${C_RED}ERROR${C_NC} (${rc_rm}): "
			err_msg+="${C_BOLD}Couldn't delete '.here':${C_NC}\n"
			err_msg+="\tis this system using GNU tooling?"
			echo -e "${err_msg}"
			error_dependencies=true
			return $rc_rm
		}
		return $rc_venv
	}
	unset venv_output
# Activate the virtualenv and add some package (to make sure pip is there)
	pip_install=$(
		source .here/bin/activate \
		&& pip install example-package-name-mc==0.0.1
	) || {
		local rc_pip=$?
		local err_msg="${C_RED}ERROR${C_NC} (${rc_pip}): "
		err_msg+="${C_BOLD}Couldn't create a Python virtualenv:${C_NC}\n"
		err_msg+="\t'pip install example-package-name-mc==0.0.1'"
		err_msg+="\n${C_BOLD}OUTPUT FOLLOWS:${C_NC}\n"
		err_msg+="${pip_install}"
		echo -e "${err_msg}"
		warning_dependencies=true
		rm --recursive --force .here || {
			local rc_rm=$?
			local err_msg="${C_RED}ERROR${C_NC} (${rc_rm}): "
			err_msg+="${C_BOLD}Couldn't delete '.here':${C_NC}\n"
			err_msg+="\tis this system using GNU tooling?"
			echo -e "${err_msg}"
			error_dependencies=true
			return $rc_rm
		}
		return $rc_pip
	}
	unset pip_install
	rm --recursive --force .here || {
		local rc_rm=$?
		local err_msg="${C_RED}ERROR${C_NC} (${rc_rm}): "
		err_msg+="${C_BOLD}Couldn't delete '.here':${C_NC}\n"
		err_msg+="\tis this system using GNU tooling?"
		echo -e "${err_msg}"
		error_dependencies=true
		return $rc_rm
	}

# Final message
	if [ ! true == "${warning_dependencies}" ] && [ ! true == "${error_dependencies}" ]; then
		echo -e "${C_BOLD}* Python virtualenv management: ${C_GREEN}OK${C_NC}"
	fi
}

# Checks for md5sum (python virtualenvs dependency)
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

# Checks for flock (python virtualenvs dependency)
check_flock() {
	if flock --version > /dev/null 2>&1; then
		echo -e "${C_BOLD}*${C_NC} ${C_BOLD}'flock'${C_NC} found: ${C_GREEN}OK${C_NC}"
	else
		local warn_msg="${C_BOLD}*${C_NC} ${C_YELLOW}WARNING:${C_NC} ${C_BOLD}'flock'${C_NC} couldn't be found.\n"
		warn_msg+="\tYou won't be able to use Python virtualenv-related features.\n"
		if [[ "${OSTYPE}" == "darwin"* ]]; then
			warn_msg+="\tYou should install ${C_BOLD}'brew install flock'${C_NC}."
		else
			warn_msg+="\tYou should install your system's ${C_BOLD}'util-linux'${C_NC} package."
		fi
		echo -e "${warn_msg}"
		warning_dependencies=true
	fi
}

# Checks for jq (aws module dependency)
check_jq() {
	if jq --version > /dev/null 2>&1; then
		echo -e "${C_BOLD}*${C_NC} ${C_BOLD}'jq'${C_NC} found: ${C_GREEN}OK${C_NC}"
	else
		local warn_msg="${C_BOLD}*${C_NC} ${C_YELLOW}WARNING:${C_NC} ${C_BOLD}'jq'${C_NC} couldn't be found.\n"
		warn_msg+="\tYou won't be able to use AWS-related features.\n"
		if [[ "${OSTYPE}" == "darwin"* ]]; then
			warn_msg+="\tYou should install ${C_BOLD}'brew install jq'${C_NC}."
		else
			warn_msg+="\tYou should install your system's ${C_BOLD}'jq'${C_NC} package."
		fi
		echo -e "${warn_msg}"
		warning_dependencies=true
	fi
}

#--
# ENTRY POINT
#--
main "$@"; exit $?
