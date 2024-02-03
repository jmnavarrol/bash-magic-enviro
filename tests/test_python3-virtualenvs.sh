#!/usr/bin/env bash
#
# Meant to be run from maketests.sh.  See its exported variables
readonly VIRTUALENVS_MODULE="${MODULES_DIR}/python3-virtualenvs.module"

if [ -z "${VIRTUALENVWRAPPER_SCRIPT}" ]; then
	err_msg="ERROR: I can't find the '' environment variable.\n"
	err_msg+="\tIs virtualenvwrapper installed and configured?"
	echo -e "${err_msg}"
	exit 1
else
	source "${VIRTUALENVWRAPPER_SCRIPT}"
fi

[ -r "${VIRTUALENVS_MODULE}" ] || {
	echo "ERROR: Couldn't find BME module '${VIRTUALENVS_MODULE}'"
	exit 1
}

# Checks if module properly manages environment variables

# Other tests
mkdir -p "${SCRATCH_DIR}/test-project"
export BME_CONFIG_DIR="${SCRATCH_DIR}"
export BME_PROJECT_DIR="${SCRATCH_DIR}/test-project"

# Loads the module
source "${VIRTUALENVS_MODULE}" || exit $?
python3-virtualenvs_load > /dev/null || exit $?

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

# virtualenv OK
load_virtualenv 'test-virtualenv' > /dev/null || exit $?
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
