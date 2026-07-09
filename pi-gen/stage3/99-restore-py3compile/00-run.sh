#!/bin/bash -e

# Undo the py3compile / py3clean diversions set up in stage1/00-qemu-py-compat
# to work around QEMU ARM64 Python segfaults. Removing the diversion renames
# the real binary back into place, so the final image ships a fully functional
# py3compile for users who install Python packages at runtime.

restore_tool() {
	local TOOL="$1"
	on_chroot << EOF
if dpkg-divert --list "${TOOL}" | grep -q .; then
	# Drop our no-op stub so --rename can move the real binary back.
	rm -f "${TOOL}"
	dpkg-divert --remove --rename "${TOOL}"
else
	echo "Warning: no diversion found for ${TOOL}; stub may not have been created." >&2
fi
EOF
}

restore_tool /usr/bin/py3compile
restore_tool /usr/bin/py3clean
