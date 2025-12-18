#!/usr/bin/env bash
#
# Copyright (c) 2018 SUSE
#
# SPDX-License-Identifier: Apache-2.0

OS_VERSION="trixie"
OS_NAME="debian"

PACKAGES="systemd coreutils init iptables chrony kmod"
REPO_COMPONENTS=${REPO_COMPONENTS:-main}
case "$ARCH" in
	(aarch64) DEB_ARCH=arm64;;
	(ppc64le) DEB_ARCH=ppc64el;;
	(s390x) DEB_ARCH="$ARCH";;
	(x86_64) DEB_ARCH=amd64; REPO_URL=${REPO_URL_X86_64:-${REPO_URL:-http://deb.debian.org/debian}};;
	(*) die "$ARCH not supported"
esac
REPO_URL=${REPO_URL:-http://deb.debian.org/debian}


if [ "$(uname -m)" != "$ARCH" ]; then
	case "$ARCH" in
		(ppc64le) cc_arch=powerpc64le;;
		(x86_64) cc_arch=x86-64;;
		(*) cc_arch="$ARCH"
	esac
	export CC="$cc_arch-linux-gnu-gcc"
fi
REPO_URL=${REPO_URL:-http://deb.debian.org/debian}

# Init process must be one of {systemd,kata-agent}
INIT_PROCESS=systemd
# List of zero or more architectures to exclude from build,
# as reported by  `uname -m`
ARCH_EXCLUDE_LIST=()
