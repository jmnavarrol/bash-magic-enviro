#!/bin/bash

# Style table
export C_BOLD='\033[1m'         # Bold text
export C_BLUE='\033[1;34m'      # Blue (and bold)
export C_GREEN='\033[1;32m'     # Green (and bold)
export C_RED='\033[1;31m'       # Red (and bold)
export C_YELLOW='\033[1;1;33m'  # Yellow (and bold)
export C_NC='\033[0m'           # No Color

# Prints 'motd-like' message
function hello_msg() {
	echo -e "${C_GREEN}WELCOME TO BME CONTAINER:${C_NC}"
	echo -e "\t* Full info about this container at ${C_BLUE}https://github.com/jmnavarrol/bash-magic-enviro${C_NC}\n"
}


#--
# MAIN-LIKE
#--
if [[ -n "${DESIRED_USERNAME-}" ]] && ! getent passwd ${DESIRED_USERNAME} > /dev/null; then
	if [[ -z "${DESIRED_UID}" ]]; then
		echo "You requested user '${DESIRED_USERNAME}' to be created but you didn't pass required environment variables:"
		echo -e "\t* DESIRED_UID: numeric uid of user."
		echo "Creation of user '${DESIRED_USERNAME}' failed! Dropping a shell"
		exec "$@"
	else
		createuser_cmd="useradd --home-dir /home/${DESIRED_USERNAME}"
		createuser_cmd+=" --uid ${DESIRED_UID}"
		if ! [ -d "/home/${DESIRED_USERNAME}" ]; then
			createuser_cmd+=" --create-home"
		else
			no_home=true
		fi
		createuser_cmd+=" --non-unique"
		createuser_cmd+=" --shell /bin/bash"
		createuser_cmd+=" --user-group"
		createuser_cmd+=" --groups sudo"
		createuser_cmd+=" ${DESIRED_USERNAME}"
		
		echo "About to create user: '${createuser_cmd}'"
		if ! $createuser_cmd; then
			echo "Creation of user '${DESIRED_USERNAME}' failed! Dropping a shell"
			exec "$@"
		else
		# Copy /etc/skel contents only if they don't exist at target
			if [[ -n "${no_home-}" ]]; then
				for item in `ls --almost-all /etc/skel/`; do
					if ! [ -e "/home/${DESIRED_USERNAME}/${item}" ]; then
						cp -d "/etc/skel/${item}" "/home/${DESIRED_USERNAME}/"
						chown "${DESIRED_USERNAME}:${DESIRED_USERNAME}" "/home/${DESIRED_USERNAME}/${item}"
					fi
				done
			fi
		# run shell as desired user
			hello_msg
			cd /home/${DESIRED_USERNAME} && su ${DESIRED_USERNAME} --login
		fi
	fi
else
# just drop in a shell
	exec "$@"
fi
