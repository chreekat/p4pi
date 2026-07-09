#!/bin/bash -e

# Under QEMU ARM64 emulation, python3.9 segfaults (exit 139) when py3compile
# invokes it (`import imp; print(imp.get_tag())`) to determine the bytecode
# cache tag. This makes the postinst of any package that byte-compiles Python
# modules (e.g. python3-picamera2 and its python3-pil dependency, installed in
# stage2) fail, aborting the whole image build.
#
# Divert py3compile/py3clean and drop a no-op in their place. dpkg-divert is
# used rather than a plain `mv` for two reasons:
#   1. It records the diversion even though python3 (and therefore py3compile)
#      is not installed in the rootfs yet at this point in stage1 - a plain
#      `mv` would silently find nothing to move.
#   2. When python3 is installed in stage2, dpkg routes the real binary to the
#      diverted name and leaves our no-op in place, so the stub survives the
#      (re)installation of the python3 packages themselves.
# stage3/99-restore-py3compile removes the diversions so the final image ships
# a working py3compile.

divert_tool() {
	local TOOL="$1"
	on_chroot << EOF
if ! dpkg-divert --list "${TOOL}" | grep -q .; then
	dpkg-divert --add --rename --divert "${TOOL}.qemu-real" "${TOOL}"
fi
cat > "${TOOL}" << 'STUB'
#!/bin/sh
# No-op during QEMU ARM image build - restored by stage3/99-restore-py3compile
exit 0
STUB
chmod 755 "${TOOL}"
EOF
}

divert_tool /usr/bin/py3compile
divert_tool /usr/bin/py3clean
