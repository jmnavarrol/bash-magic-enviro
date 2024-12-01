#!/usr/bin/env bash

# Manages BME's install-related processes
#
# Expected environment variables:
# BUILDDIR: the output directory (output file will be ${BUILDDIR}/${BME_BASENAME})
# DESTDIR: BME install dir

# GLOBALS
readonly MANDATORY_VARS=(
	'BUILDDIR'
	'DESTDIR'
)
readonly BASE_DIR=$(dirname $(readlink --canonicalize --verbose ${BASH_SOURCE[0]}))
readonly INSTALL_TRACKER="${BASE_DIR}/.MANIFEST"
readonly DEV_TRACKER="${BASE_DIR}/.MANIFEST.DEV"


#---
# LOCAL FUNCTIONS
#---
# Checks environment
check_environment() {
	for mandatory_var in ${MANDATORY_VARS[@]}; do
		if [ -z "${!mandatory_var}" ]; then
			echo -e "${C_RED}ERROR:${C_NC} Mandatory environment variable ${C_BOLD}'${mandatory_var}'${C_NC} is unset or empty."
			exit 1
		fi
	done
}


# BME full install
make_install() {
# Cleaning previous install (if any)
	uninstall_output=$(make_uninstall) || {
		local rc=$?
		local err_msg="${C_RED}ERROR${C_NC} (${rc}):"
		err_msg+=" ${C_BOLD}while cleaning previous install${C_NC}.  Output follows:\n"
		err_msg+="${uninstall_output}"
		echo -e "${err_msg}"
		unset uninstall_output
		return $rc
	}
	unset uninstall_output

# Now, the install process itself
	mkdir --parents "${DESTDIR}/" || return $?
	find "${BUILDDIR}" -mindepth 1 -printf '%P\n' \
	| while read install_item; do
		if [ -d "${BUILDDIR}/${install_item}" ]; then
			mkdir --parents "${DESTDIR}/${install_item}" || return $?
		else
			cp --no-dereference --preserve=all \
				"${BUILDDIR}/${install_item}" \
				"${DESTDIR}/${install_item}" \
				|| return $?
			echo "${DESTDIR}/${install_item}" >> "${INSTALL_TRACKER}"
		fi
	done
}


# BME development mode
make_dev() {
# Cleaning previous install (if any)
	uninstall_output=$(make_uninstall) || {
		local rc=$?
		local err_msg="${C_RED}ERROR${C_NC} (${rc}):"
		err_msg+=" ${C_BOLD}while cleaning previous install${C_NC}.  Output follows:\n"
		err_msg+="${uninstall_output}"
		echo -e "${err_msg}"
		unset uninstall_output
		return $rc
	}
	unset uninstall_output

# Now, the dev install process itself
	mkdir --parents "${DESTDIR}/" || return $?
	find "${BUILDDIR}" -mindepth 1 -maxdepth 1 -printf '%P\n' \
	| while read install_item; do
		if [ -e "${DESTDIR}/${install_item}" ]; then
			echo -e "\t${C_YELLOW}WARNING:${C_NC} deleting '${DESTDIR}/${install_item}'"
			rm --force --recursive "${DESTDIR}/${install_item}"
		fi
		ln --symbolic \
			"${BUILDDIR}/${install_item}" \
			"${DESTDIR}/${install_item}" \
			|| return $?
		echo "${DESTDIR}/${install_item}" >> "${DEV_TRACKER}"
	done
	unset install_item
}


# BME uninstall
make_uninstall() {
# Grabs info about previous install processes
	for tracker in "${INSTALL_TRACKER}" "${DEV_TRACKER}"; do
		if [ -r "${tracker}" ]; then
			echo -e "\t${C_GREEN}INFO:${C_NC} loading setup info from ${C_BOLD}'${tracker}'${C_NC}"
			while read -r line; do
				local msg="\t${C_YELLOW}WARNING${C_NC}:"
				msg+=" deleting '${line}'."
				echo -e "${msg}"
				rm --force --recursive "${line}" || return $?
				local parent_dir=$(dirname "${line}")
				if [ -d "${parent_dir}" ]; then
					empty_dir=$(find "${parent_dir}" -maxdepth 0 -empty)
					if [ -n "${empty_dir}" ]; then
						local msg="\t${C_YELLOW}WARNING${C_NC}:"
						msg+=" deleting empty dir '${parent_dir}'."
						echo -e "${msg}"
						rmdir "${parent_dir}"
					fi
					unset empty_dir
				fi
			done < "${tracker}"
			unset line
			rm --force "${tracker}"
		else
			echo -e "\t${C_YELLOW}WARNING:${C_NC} install info file ${C_BOLD}'${tracker}'${C_NC} couldn't be found."
		fi
	done
	unset tracker
}



#---
# MAIN
#---
# Check entry parameters
if (( ${#} != 1 )); then
	echo -e "${C_RED}ERROR:${C_NC} Only one parameter allowed.  Got ${C_BOLD}${#}${C_NC}: ${C_BOLD}'${@}'${C_NC}"
	exit 1
fi

check_environment

# Operates on the given option
case "$1" in
	'install' \
	| 'dev' \
	| 'uninstall')
		make_${1} || exit $?
	;;
	*)
		echo -e "${C_RED}ERROR:${C_NC} Requested operation was ${C_BOLD}'${1}'${C_NC}."
		echo -e "\tValid operations: ${C_BOLD}'install', 'dev', 'uninstall'${C_NC}."
		exit 1
esac
