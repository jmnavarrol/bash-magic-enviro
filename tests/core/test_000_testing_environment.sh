#!/usr/bin/env bash
# Meant to be run from maketests.sh.  See its exported variables.

# Tests the testing framework itself

function main() {
	echo "PATH IS: '${PATH}'"
	echo "HOME IS: '${HOME}'"
# Test loading main BME function
	if ! . bash-magic-enviro; then
		echo "Please make sure 'bash-magic-enviro' is installed and in your path!"
		return -1
	fi
}

main; exit $?
