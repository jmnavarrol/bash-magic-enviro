# Helper functions that can be used by unit tests
# Meant to be sourced from main maketests.sh script.

# Strips ANSI escape codes/sequences so tests can assert return messages with ease.
# $1 message to sanitize
function strip_escape_codes() {
local raw_input="${1}"
local stripped_output=''
# locals for each line
local _i _char _escape=0

	for line in "${raw_input}"; do
		local stripped_line=''
		for (( _i=0; _i < ${#line}; _i++ )); do
			_char="${line:_i:1}"
			if (( ${_escape} == 1 )); then
				if [[ "${_char}" == [a-zA-Z] ]]; then
					_escape=0
				fi
				continue
			fi
			if [[ "${_char}" == $'\e' ]]; then
				_escape=1
				continue
			fi
			stripped_line+="${_char}"
		done
		stripped_output+="${stripped_line}"
	done

	echo -en "${stripped_output}"
}
export -f strip_escape_codes

