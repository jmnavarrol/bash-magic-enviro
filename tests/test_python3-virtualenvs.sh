#!/usr/bin/env bash

# Meant to be run from maketests.sh.  See its exported variables
readonly VIRTUALENVS_MODULE="${MODULES_DIR}/python3-virtualenvs.module"

# Checks environment
if [ -z "${VIRTUALENVWRAPPER_SCRIPT}" ]; then
	err_msg="ERROR: I can't find the '' environment variable.\n"
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
python3-virtualenvs_load || exit $?

#--
# Virtualenv creation
#--
# virtualenv without param
stripped_output=''
for line in "$(load_virtualenv)"; do
	strip_escape_codes "${line}" line_stripped
	stripped_output+="${line_stripped}"
done

if [[ "${stripped_output}" =~ .*"mandatory param 'venv_name' not set".* ]]; then
	echo -e "Check 'virtualenv without param': OK"
else
	echo "Check 'virtualenv without param': FAIL"
	echo "OUTPUT:"
	echo -e "${stripped_output}"
	echo "END OF OUTPUT"
	exit 1
fi

# simple virtualenv OK
echo "Check simple virtualenv creation"
load_virtualenv 'test-virtualenv' || exit $?
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
deactivate
rmvirtualenv 'test-virtualenv' || exit $?

# virtualenv with requestfile extra param
echo "Check virtualenv with optional requirements file"
mkdir --parents "${BME_PROJECT_DIR}/requirements_subdir"
echo -e 'hello-hello' > "${BME_PROJECT_DIR}/requirements_subdir/requirements.txt"
load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' || exit $?

# Load it again without changes
echo "Check virtualenv loading with no changes"
deactivate
load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' || exit $?

# Load once again, this time with a change
deactivate
echo "Check upgrading virtualenv with changes"
echo -e 'wheel' >> "${BME_PROJECT_DIR}/requirements_subdir/requirements.txt"
load_virtualenv 'test-virtualenv' 'requirements_subdir/requirements.txt' || exit $?

#--
# CLEAN
#--
python3-virtualenvs_unload || exit $?
rmvirtualenv 'test-virtualenv'
