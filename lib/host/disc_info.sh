#!/bin/sh

set -e

[ "${DEBUG}" ] && set -x

print_usage(){
	:
}

print_error(){ >&2 printf '\033[31;1mERROR: %s\033[0m\n' "${@}"; }
verify_file_readable(){
	if [ -r "${1}" ]; then
		printf %s "${1}"; return 0;
	else
		print_error "${1} not found (or not readable)"
		return 7;
	fi
}

if [ ${#} -ne 1 ]; then print_error 'required argument was not provided. check usage'; exit 7; fi
if ! { command -v isoinfo >/dev/null 2>&1 ; }; then print_error 'depenency `isoinfo` not available'; fi

case "${1}" in
	/*)
		device=$(verify_file_readable "${1}")
		;;
	*)
		device=$(verify_file_readable "/dev/${1}")
		;;
esac

_output=$(isoinfo -d -i "${device}")

get_field() {
	case $1 in
		bs)
			local field='Logical block size is'
			;;
		count)
			local field='Volume size is'
			;;
		*)
			print_error 'unknown field requested from `isoinfo`'
			return 9
			;;
	esac
	echo "${_output}" | awk -F': ' "/${field}/ {print \$NF}";
}

bs=$(get_field bs)
count=$(get_field count)

printf '{\n\t"block_size": %s,\n\t"count": %s\n}\n' $bs $count
