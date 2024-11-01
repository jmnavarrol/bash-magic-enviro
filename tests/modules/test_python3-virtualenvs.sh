#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables

# Tests the python3-virtualenvs module

readonly VIRTUALENVS_MODULE="${BUILDDIR}/bash-magic-enviro_modules/python3-virtualenvs.module"
# WARNING: For these tests you should make sure you have virtualenvwrapper script installed and its path.
readonly VIRTUALENVWRAPPER_SCRIPT='/usr/share/virtualenvwrapper/virtualenvwrapper.sh'


#--
# MAIN
#--
# Sets environment
export HOME="${SCRATCH_DIR}"
source "${BUILDDIR}/bash-magic-enviro" || exit $?
source "${VIRTUALENVWRAPPER_SCRIPT}" || {
	local_rc=$?
	err_msg="${C_BOLD}'${VIRTUALENVWRAPPER_SCRIPT}'${C_NC} wasn't found.\n"
	err_msg+="\tMake sure you installed ${C_BOLD}'virtualenvwrapper'${C_NC} and this script points to the proper path."
	bme_log "${err_msg}" error
	exit $local_rc
}

mkdir --parents "${SCRATCH_DIR}/test-project"
export BME_PROJECT_DIR="${SCRATCH_DIR}/test-project"
cd "${BME_PROJECT_DIR}"

# Loads the module
source "${VIRTUALENVS_MODULE}" || exit $?
python3-virtualenvs_load || exit $?

#--
# Virtualenv creation
#--
# virtualenv without param
function_output=$(load_virtualenv 2>&1)
stripped_output=$(strip_escape_codes "${function_output}")

if [[ "${stripped_output}" =~ .*"mandatory param 'venv_name' not set".* ]]; then
	bme_log "Check ${C_BOLD}'virtualenv without param'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
else
	bme_log "Check ${C_BOLD}'virtualenv without param'${C_NC}: ${C_RED}FAIL${C_NC}"
	bme_log "${C_BOLD}OUTPUT${C_NC}"
	bme_log "${function_output}" '' 1
	bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
fi

# simple virtualenv OK
function_output=$(load_virtualenv 'test-virtualenv' 2>&1) || rc=$?
if [[ -n $rc ]]; then
	bme_log "Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}"
	bme_log "${C_BOLD}OUTPUT${C_NC}"
	bme_log "${function_output}" '' 1
	bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
fi

# Check results
for file in \
	"${BME_PROJECT_DIR}/${BME_HIDDEN_DIR}/python-virtualenvs.lockfile" \
	"${BME_PROJECT_DIR}/${BME_HIDDEN_DIR}/python-virtualenvs.md5"
do
		if ! [ -r "${file}" ]; then
			err_msg="Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}\n"
			err_msg+="\tExpected file ${C_BOLD}'${file}'${C_NC} not found."
			bme_log "${err_msg}"
			exit 1
		fi
done
rmvirtualenv 'test-virtualenv' || exit $?
bme_log "Check ${C_BOLD}'empty virtualenv creation'${C_NC}: ${C_GREEN}OK${C_NC}" info 1

# virtualenv with requestfile extra param
mkdir --parents "${BME_PROJECT_DIR}/requirements_subdir"
echo -e 'hello-hello' > "${BME_PROJECT_DIR}/requirements_subdir/requirements.txt"

function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]]; then
	bme_log "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}: ${C_RED}FAIL${C_NC}"
	bme_log "${C_BOLD}OUTPUT${C_NC}"
	bme_log "${function_output}" '' 1
	bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
	bme_log "Check ${C_BOLD}'parameterized virtualenv creation'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
fi

# Load it again without changes
function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]]; then
	bme_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}: ${C_RED}FAIL${C_NC}"
	bme_log "${C_BOLD}OUTPUT${C_NC}"
	bme_log "${function_output}" '' 1
	bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
	bme_log "Check ${C_BOLD}'parameterized virtualenv reactivation'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
fi

# Load once again, this time with a change
echo -e 'wheel' >> "${BME_PROJECT_DIR}/requirements_subdir/requirements.txt"
function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]]; then
	bme_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}: ${C_RED}FAIL${C_NC}"
	bme_log "${C_BOLD}OUTPUT${C_NC}"
	bme_log "${function_output}" '' 1
	bme_log "${C_BOLD}END OF OUTPUT${C_NC}"
	exit $rc
else
	unset rc
	bme_log "Check ${C_BOLD}'parameterized virtualenv update'${C_NC}: ${C_GREEN}OK${C_NC}" info 1
fi

#--
# CLEAN
#--
python3-virtualenvs_unload || exit $?
