#!/usr/bin/env bash

# Meant to be run from maketests.sh.  See its exported variables
readonly VIRTUALENVS_MODULE="${MODULES_DIR}/python3-virtualenvs.module"


#--
# MAIN
#--
# Checks environment
if [ -z "${VIRTUALENVWRAPPER_SCRIPT}" ]; then
	err_msg="ERROR: I can't find the 'VIRTUALENVWRAPPER_SCRIPT' environment variable.\n"
	err_msg+="\tIs virtualenvwrapper installed and configured?"
	echo -e "${err_msg}"
	exit 1
else
	source "${VIRTUALENVWRAPPER_SCRIPT}" || exit $?
fi

[ -r "${VIRTUALENVS_MODULE}" ] || {
	echo "ERROR: Couldn't find BME module '${VIRTUALENVS_MODULE}'"
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
	echo "Check 'module loading': FAIL"
	echo -e "${function_output}"
	exit $rc
else
	unset rc
	echo -e "Check 'python3-virtualenvs module loading': OK"
fi

#--
# Virtualenv creation
#--
# virtualenv without param
python3-virtualenvs_load > /dev/null

function_output=$(load_virtualenv 2>&1)
stripped_output=$(strip_escape_codes "${function_output}")

if [[ "${stripped_output}" =~ .*"mandatory param 'venv_name' not set".* ]]; then
	echo -e "Check 'virtualenv without param': OK"
else
	echo "Check 'virtualenv without param': FAIL"
	echo "OUTPUT:"
	echo -e "${function_output}"
	echo "END OF OUTPUT"
	exit 1
fi

# simple virtualenv OK
function_output=$(load_virtualenv 'test-virtualenv' 2>&1) || rc=$?
if [[ -n $rc ]] then
	echo "Check 'empty virtualenv creation': FAIL"
	echo "OUTPUT:"
	echo -e "${function_output}"
	echo "END OF OUTPUT"
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
			echo "TEST ERROR: expected file '${file}' not there"
			exit 1
		fi
done
rmvirtualenv 'test-virtualenv' > /dev/null || exit $?
echo "Check 'simple virtualenv creation': OK"

# virtualenv with requestfile extra param
mkdir --parents "${BME_PROJECT_DIR}/requirements_subdir"
echo -e 'hello-hello' > "${BME_PROJECT_DIR}/requirements_subdir/requirements.txt"

function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]] then
	echo "Check 'parameterized virtualenv creation': FAIL"
	echo "OUTPUT:"
	echo -e "${function_output}"
	echo "END OF OUTPUT"
	exit $rc
else
	unset rc
	echo -e "Check 'parameterized virtualenv creation': OK"
fi

# Load it again without changes
function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]] then
	echo "Check 'parameterized virtualenv reactivation': FAIL"
	echo "OUTPUT:"
	echo -e "${function_output}"
	echo "END OF OUTPUT"
	exit $rc
else
	unset rc
	echo -e "Check 'parameterized virtualenv reactivation': OK"
fi

# Load once again, this time with a change
echo -e 'wheel' >> "${BME_PROJECT_DIR}/requirements_subdir/requirements.txt"
function_output=$(load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' 2>&1) || rc=$?
if [[ -n $rc ]] then
	echo "Check 'parameterized virtualenv update': FAIL"
	echo "OUTPUT:"
	echo -e "${function_output}"
	echo "END OF OUTPUT"
	exit $rc
else
	unset rc
	echo -e "Check 'parameterized virtualenv update': OK"
fi

#--
# CLEAN
#--
python3-virtualenvs_unload || exit $?
rmvirtualenv 'test-virtualenv' > /dev/null || exit $?
