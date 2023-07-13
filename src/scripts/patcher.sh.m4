#!/bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.10.0
# ARG_OPTIONAL_BOOLEAN([check-dependencies], , [Check whether all dependencies needed for the script are installed], [on])
# ARG_OPTIONAL_BOOLEAN([check-compatibility], , [Check whether the kernel is compatible with this module], [on])
# ARGBASH_SET_DELIM([ =])
# ARG_OPTION_STACKING([getopt])
# ARG_HELP([Patch the DSDT ACPI Table])
# ARGBASH_GO

# [ <-- needed because of Argbash

### Vars ###

PACKAGE_VERSION="1.0"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SOURCE_DIR="${SCRIPT_DIR}/src"
PATCHES_DIR="${SOURCE_DIR}/patches"
DIST_DIR="${SCRIPT_DIR}/dist"
RUN_DIR="$(pwd)"
WORK_DIR="/tmp/dsdt_patcher"

### Exit Function ###

trap "exit 1" TERM
export TOP_PID=$$
_die() {
	kill -s TERM $TOP_PID
}

### Logging ###

_log() {
	echo "${3:-}[${1}] ${2}"
}

_log_info() {
	_log "INFO" "${1}" "${2:-}"
}

_log_error() {
	_log "ERROR" "${1}" "${2:-}"
}

_log_done() {
	_log "DONE" "${1}" "${2:-}"
}

### Dependency Check ###

_check_dependency (){
	type "${1}" &> /dev/null;
}

_dependency_fulfilled() {
	_log_info "Dependency '${1}' is fulfilled!" "  > "
}

_dependency_missing() {
	_log_error "Dependency '${1}' is missing!" "  > "
	_die
}

_check_dependencies() {
	if [[ ${_arg_check_dependencies} == "on" ]]; then
		_log_info "Running dependency check..."
		DEPENDENCIES=(sudo acpidump acpixtract iasl cpio find)
		for DEPENDENCY in ${DEPENDENCIES[@]}; do
			_check_dependency "${DEPENDENCY}" && _dependency_fulfilled "${DEPENDENCY}" || _dependency_missing "${DEPENDENCY}"
		done
	else 
		_log_info "Skipping dependency check..."
	fi
}

### Compatibility Check ###

_compatible_equal () {
	if [[ "${1}" == "${2}" ]]; then
		return "0"
	else
		return "1"
	fi
}

_is_compatible() {
	_log_info "${1} (${2}) is compatible!" "  > "
}

_not_compatible() {
	_log_error "${1} (${2}) is not compatible! (Should be ${3})" "  > "
	_die
}

_check_compatibility_equals() {
	if [[ ${_arg_check_compatibility} == "on" ]]; then
		_log_info "Running compatibility check..."
		if [[ -f "/sys/class/dmi/id/product_name" ]];then
			PRODUCT_NAME=$(cat "/sys/class/dmi/id/product_name")
		else 
			PRODUCT_NAME=$(sudo dmidecode -s system-product-name)
		fi

		if [[ -f "/sys/class/dmi/id/sys_vendor" ]];then
			SYS_VENDOR=$(cat "/sys/class/dmi/id/sys_vendor")
		else 
			SYS_VENDOR=$(sudo dmidecode -s system-manufacturer)
		fi
		COMPATIBLE_SYS_VENVOR=("System Vendor" "${SYS_VENDOR}" "LENOVO")
		COMPATIBLE_PRODUCT_NAME=("System Vendor" "${PRODUCT_NAME}" "82YU")
		COMPTABILES=(COMPATIBLE_SYS_VENVOR COMPATIBLE_PRODUCT_NAME)
		COMPTABILES_EQUALS=(COMPTABILES)
		declare -n COMPATBILITY_ENTRY COMPATBILITY_VALUES
		for COMPATBILITY_ENTRY in "${COMPTABILES_EQUALS[@]}"; do
		    for COMPATBILITY_VALUES in "${COMPATBILITY_ENTRY[@]}"; do
		        _compatible_equal "${COMPATBILITY_VALUES[1]}" "${COMPATBILITY_VALUES[2]}" && _is_compatible "${COMPATBILITY_VALUES[0]}" ${COMPATBILITY_VALUES[1]} || _not_compatible "${COMPATBILITY_VALUES[0]}" "${COMPATBILITY_VALUES[1]}" "${COMPATBILITY_VALUES[2]}"
		    done
		done
	else 
		_log_info "Skipping compatibility check..."
	fi
}

### Working Directory ###

_create_workdir() {
	_log_info "Creating Workdir..."
	rm -rf "${WORK_DIR}" || true
	mkdir "${WORK_DIR}"
	_log_done "Workdir '${WORK_DIR}' created!" "  > "
}

### DSDT ###

_extract_dsdt() {
	_log_info "Extracting DSDT ACPI table..."

	PREVIOUS_DIR="$(pwd)"
	ACPIDUMP_DIR="${WORK_DIR}/acpidump-$(date +%H%M%S)"
	mkdir "${ACPIDUMP_DIR}"
	sudo acpidump > "${ACPIDUMP_DIR}/acpidump"
	cd "${ACPIDUMP_DIR}"
	acpixtract "${ACPIDUMP_DIR}/acpidump"
	iasl -va -d dsdt.dat
	mv dsdt.dsl "${WORK_DIR}"
	cd "${PREVIOUS_DIR}"
	rm -rf "${ACPIDUMP_DIR}"

	_log_done "DSDT ACPI table extracted!" "  > "
}

_patch_dsdt() {
	_log_info "Patching extracted DSDT ACPI table..."
	find "${PATCHES_DIR}" -type f -exec \
	  patch --batch --no-backup-if-mismatch --reject-file=/dev/null \
	  "${WORK_DIR}/dsdt.dsl" '{}' \;
	_log_done "Exctracted DSDT ACPI table pacthed!" "  > "
}

_compile_dsdt() {
	iasl -va -sa "${WORK_DIR}/dsdt.dsl"
	mkdir -p "${WORK_DIR}/kernel/firmware/acpi"
	mv "${WORK_DIR}/dsdt.aml" "${WORK_DIR}/kernel/firmware/acpi"
	mkdir -p "${SCRIPT_DIR}/dist/"
	find "${WORK_DIR}/kernel" | cpio -H newc --create > "${SCRIPT_DIR}/dist/patched_dsdt.img"
}

_psa() {
	echo
	echo "==============================================================================================================================="
	echo
	_log_info "The Patched DSDT was created as an initital ramdisk and saved as 'dist/patched_dsdt.img'..."
	_log_info "To use the ramdisk, copy it into your /boot/ directory, then edit your bootloader (eg. grub/systemd-boot) to use the initd:"
	_log_info "'cp dist/patched_dsdt.img /boot/patched_dsdt.img' " " > "
	_log_info "'initrd /patched_dsdt.img'" " > "
	_log_done "For more information, visit: https://docs.kernel.org/admin-guide/acpi/initrd_table_override.html"
}

### Entrypoint ###

_main() {
	_check_dependencies
	_check_compatibility_equals
	_create_workdir
	_extract_dsdt
	_patch_dsdt
	_compile_dsdt
	_psa
}

_main "$@"



# ] <-- needed because of Argbash





