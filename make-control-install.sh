#!/usr/bin/env bash

# Manages BME's install-related processes
#
# Expected environment variables:
# SRCDIR: directory holding source code
# SCRIPT: name of the main BME script (and derivatives)
# VERSION_FILE: the name of templated file (its source will be found at ${SRCDIR}/${VERSION_FILE}.tpl)
# BUILDDIR: the output directory (output file will be ${BUILDDIR}/${SCRIPT})
# DESTDIR: BME install dir

# GLOBALS
readonly MANDATORY_VARS=(
	'SRCDIR'
	'SCRIPT'
	'VERSION_FILE'
	'BUILDDIR'
	'DESTDIR'
)
readonly INSTALL_TRACKER='./.installdir'
readonly DEV_TRACKER='./.devinstalldir'


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
	for bme_item in "${SCRIPT}" "${VERSION_FILE}" "${SCRIPT}_modules"; do
		if [ -L ${DESTDIR}/${bme_item} ]; then
			echo -e "${C_YELLOW}WARNING:${C_NC} deleting ${C_BOLD}'${DESTDIR}/${bme_item}${C_NC}'"
			rm -rf "${DESTDIR}/${bme_item}"
		fi
	done
	cp --archive --verbose ${BUILDDIR}/. ${DESTDIR}
	echo "LAST_INSTALL_DIR=${DESTDIR}" > "${INSTALL_TRACKER}"
}


# BME development mode
make_dev() {
# Symlinks source files
	for bme_item in "${SCRIPT}" "${SCRIPT}_modules"; do
		if ! [ -L ${DESTDIR}/${bme_item} ]; then
			if [ -e ${DESTDIR}/${bme_item} ]; then
				echo -e "${C_YELLOW}WARNING:${C_NC} deleting ${C_BOLD}'${DESTDIR}/${bme_item}${C_NC}'"
				rm -rf "${DESTDIR}/${bme_item}"
			fi
			echo -e "${C_GREEN}INFO:${C_NC} creating ${C_BOLD}'${DESTDIR}/${bme_item}'${C_NC} symlink for development"
			current_pwd="${PWD}"
			( cd ${DESTDIR} && ln -s ${current_pwd}/${SRCDIR}/${bme_item} ${bme_item} )
		fi
	done
# Templated files need to be taken from build directory
	if ! [ -L ${DESTDIR}/${VERSION_FILE} ]; then
		if [ -e ${DESTDIR}/${VERSION_FILE} ]; then
			echo -e "${C_YELLOW}WARNING:${C_NC} deleting ${C_BOLD}'${DESTDIR}/${VERSION_FILE}'${C_NC}"
			rm -rf "${DESTDIR}/${VERSION_FILE}"
		fi
		echo -e "${C_GREEN}INFO:${C_NC} creating ${C_BOLD}'${DESTDIR}/${VERSION_FILE}'${C_NC} symlink for development"
		current_pwd="${PWD}"
		( cd ${DESTDIR} && ln -s ${current_pwd}/${BUILDDIR}/${VERSION_FILE} ${VERSION_FILE} )
	fi
	echo "LAST_DEV_DIR=${DESTDIR}" > "${DEV_TRACKER}"
}


# BME uninstall
make_uninstall() {
local LAST_INSTALL_DIR="${DESTDIR}"
local LAST_DEV_DIR="${DESTDIR}"
local uninstall_dirs=("${DESTDIR}")

# Grabs info about previous install processes
	for tracker in "${INSTALL_TRACKER}" "${DEV_TRACKER}"; do
		if [ -r "${tracker}" ]; then
			echo -e "\t${C_GREEN}INFO:${C_NC} loading setup info from ${C_BOLD}'${tracker}'${C_NC}"
			source "${tracker}"
		fi
	done
# Prepares a list of directories to uninstall from
	for directory in "${LAST_INSTALL_DIR}" "${LAST_DEV_DIR}"; do
	# this adds directory to the uninstall dirs array if not yet included
		if [[ ! " ${uninstall_dirs[*]} " =~ " ${directory} " ]]; then
			uninstall_dirs+=("${directory}")
		fi
	done
# The uninstall process itself
	for directory in "${uninstall_dirs[@]}"; do
		echo -e "\t${C_GREEN}INFO:${C_NC} Uninstalling from ${C_BOLD}'${directory}'${C_NC}"
		rm -rf "${directory}/${SCRIPT}"
		rm -rf "${directory}/${VERSION_FILE}"
		rm -rf "${directory}/${SCRIPT}_modules"
	done
	rm -rf "${INSTALL_TRACKER}" "${DEV_TRACKER}"
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
		make_${1}
	;;
	*)
		echo -e "${C_RED}ERROR:${C_NC} Requested operation was ${C_BOLD}'${1}'${C_NC}."
		echo -e "\tValid operations: ${C_BOLD}'install', 'dev', 'uninstall'${C_NC}."
		exit 1
esac
