#!/usr/bin/env bash

#--
# Script entrypoint (see the end of this file to understand)
#--
main() {
	echo "NUMBER OF CMD PARAMETERS: '${#}'"
	if (( $# > 0 )); then
		echo "GOT CMD PARAMETERS: '${@}'"
	else
		echo "HELLO FROM MAIN (without parameters)"
	fi

# function using "pseudo-named parameters"
# 	a='hello world' \
# 	c="${PWD}" my_function || return $?
	a='hello world' \
	b=3 \
	c="${PWD}" my_function || return $?

# prove variables didn't leak
	echo "FROM MAIN (these should be empty): '${a}', '${b}', '${c}'."
	other_function

# prove the script exits with main's RC
	return 1
}

# A function with "named parameters"
# See https://stackoverflow.com/questions/12128296/is-there-a-way-to-avoid-positional-arguments-in-bash
# a: a mandatory parameter
# b: an optional parameter
# c: another optional paramenter
my_function() {
	for mandatory_variable in 'a' 'b'; do
		if [ -z "${!mandatory_variable}" ]; then
			echo "ERROR: '${mandatory_variable}' variable is mandatory."
			return 1
		fi
	done

	echo "HELLO, FROM FUNCTION: '${a}', '${b}', '${c}'."
}

other_function() {
	echo "HELLO, FROM OTHER FUNCTION (these should be empty too): '${a}'."
}

# trick so main can be at the beginning of the file
# See https://unix.stackexchange.com/questions/449498/call-function-declared-below
main "$@"; exit $?
