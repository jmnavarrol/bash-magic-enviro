#!/usr/bin/env bash

# Meant to be run from maketests.sh.  See its exported variables
readonly VIRTUALENVS_MODULE="${MODULES_DIR}/python3-virtualenvs.module"


#--
# MAIN
#--
# Checks environment
if [ -z "${VIRTUALENVWRAPPER_SCRIPT}" ]; then
	err_msg="I can't find the ${C_BOLD}'VIRTUALENVWRAPPER_SCRIPT'${C_NC} environment variable.\n"
	err_msg+="\tIs virtualenvwrapper installed and configured?"
	btest_log "${err_msg}" error
	exit 1
else
	source "${VIRTUALENVWRAPPER_SCRIPT}" || exit $?
fi

[ -r "${VIRTUALENVS_MODULE}" ] || {
	btest_log "Couldn't find BME module ${C_BOLD}'${VIRTUALENVS_MODULE}'${C_NC}." error
	exit 1
}

# Sets environment
mkdir -p "${SCRATCH_DIR}/test-project"
export BME_CONFIG_DIR="${SCRATCH_DIR}"
export BME_PROJECT_DIR="${SCRATCH_DIR}/test-project"
cd "${BME_PROJECT_DIR}"

# Loads the module
source "${VIRTUALENVS_MODULE}"
function_output=$(python3-virtualenvs_load) || rc=$?
if [[ -n $rc ]] then
	btest_log "Check ${C_BOLD}'module loading'${C_NC}: ${C_RED}FAIL${C_NC}"
	btest_log "${C_BOLD}OUTPUT${C_NC}"
	btest_log "${function_output}" '' 1
	btest_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
	echo -e "Check ${C_BOLD}'module loading'${C_NC}: ${C_GREEN}OK${C_NC}"
fi

#--
# Virtualenv creation
#--
# virtualenv without param
python3-virtualenvs_load > /dev/null

function_output=$(load_virtualenv 2>&1)
stripped_output=$(strip_escape_codes "${function_output}")

if [[ "${stripped_output}" =~ .*"mandatory param 'venv_name' not set".* ]]; then
	btest_log "Check ${C_BOLD}'virtualenv without param'${C_NC}: ${C_GREEN}OK${C_NC}"
else
	btest_log "Check ${C_BOLD}'virtualenv without param'${C_NC}: ${C_RED}FAIL${C_NC}"
	btest_log "${C_BOLD}OUTPUT${C_NC}"
	btest_log "${function_output}" '' 1
	btest_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
fi

# simple virtualenv OK
function_output=$(load_virtualenv 'test-virtualenv' 2>&1) || rc=$?
if [[ -n $rc ]] then
	btest_log "Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}"
	btest_log "${C_BOLD}OUTPUT${C_NC}"
	btest_log "${function_output}" '' 1
	btest_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
fi

# Check results
for file in \
	"${BME_CONFIG_DIR}/python-virtualenvs.lockfile" \
	"${BME_CONFIG_DIR}/python-virtualenvs.md5"
do
		if ! [ -r "${file}" ]; then
			err_msg="Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}\n"
			err_msg+="\tExpected file ${C_BOLD}'${file}'${C_NC} not found."
			btest_log "${err_msg}"
			exit 1
		fi
done
rmvirtualenv 'test-virtualenv' > /dev/null || exit $?
btest_log "Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_GREEN}OK${C_NC}"

# virtualenv with requestfile extra param
mkdir --parents "${BME_PROJECT_DIR}/requirements_subdir"
echo -e 'hello-hello' > "${BME_PROJECT_DIR}/requirements_subdir/requirements.txt"

function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]] then
	btest_log "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}"
	btest_log "${C_BOLD}OUTPUT${C_NC}"
	btest_log "${function_output}" '' 1
	btest_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
	echo -e "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}: ${C_GREEN}OK${C_NC}"
fi

# Load it again without changes
function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]] then
	btest_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}: ${C_RED}FAIL${C_NC}"
	btest_log "${C_BOLD}OUTPUT${C_NC}"
	btest_log "${function_output}" '' 1
	btest_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
	btest_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}: ${C_GREEN}OK${C_NC}"
fi

# Load once again, this time with a change
echo -e 'wheel' >> "${BME_PROJECT_DIR}/requirements_subdir/requirements.txt"
function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]] then
	btest_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}: ${C_RED}FAIL${C_NC}"
	btest_log "${C_BOLD}OUTPUT${C_NC}"
	btest_log "${function_output}" '' 1
	btest_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
	btest_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}: ${C_GREEN}OK${C_NC}"
fi

#--
# CLEAN
#--
python3-virtualenvs_unload || exit $?
rmvirtualenv 'test-virtualenv' > /dev/null || exit $?
