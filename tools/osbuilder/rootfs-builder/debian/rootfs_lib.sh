#!/usr/bin/env bash
#
# Copyright (c) 2018 Yash Jain, 2022 IBM Corp.
#
# SPDX-License-Identifier: Apache-2.0

build_rootfs() {
  local rootfs_dir=$1
  local COMMA_PKGS=$(echo "$ALL_PKGS" | xargs | tr ' ' ',')
  
  PACKAGES=$(echo "$PACKAGES" | tr ' ' ',')
  EXTRA_PKGS=$(echo "$EXTRA_PKGS" | tr ' ' ',')
  local ALL_PKGS="${PACKAGES} ${EXTRA_PKGS}"
  local COMMA_PKGS=$(echo "$ALL_PKGS" | xargs | tr ' ' ',')

  apt update
  echo "INFO: Rodando mmdebstrap..."
  echo $OS_VERSION
  if ! mmdebstrap --mode auto --arch="$DEB_ARCH" --variant required \
      --components="$REPO_COMPONENTS" \
      --include "$PACKAGES,$EXTRA_PKGS" "$OS_VERSION" "$rootfs_dir" "$REPO_URL"; then
    echo "ERROR: mmdebstrap falhou. Verifique se o pacote está instalado no host/container." && exit 1
  else
    echo "INFO: mmdebstrap succeeded"
  fi
  rm -rf "$rootfs_dir/var/run"
  ln -s /run "$rootfs_dir/var/run"
  cp --remove-destination /etc/resolv.conf "$rootfs_dir/etc"

  local dir="$rootfs_dir/etc/ssl/certs"
  mkdir -p "$dir"
  cp --remove-destination /etc/ssl/certs/ca-certificates.crt "$dir"

  # Reduce image size and memory footprint by removing unnecessary files and directories.
  rm -rf $rootfs_dir/usr/share/{bash-completion,bug,doc,info,lintian,locale,man,menu,misc,pixmaps,terminfo,zsh}

  echo "INFO: Criando nós de dispositivo estáticos..."
  pushd "$rootfs_dir/dev" >/dev/null
  
  # Dispositivos padrão essenciais
  [ ! -e console ] && mknod -m 600 console c 5 1
  [ ! -e null ]    && mknod -m 666 null c 1 3
  [ ! -e zero ]    && mknod -m 666 zero c 1 5
  [ ! -e random ]  && mknod -m 666 random c 1 8
  [ ! -e urandom ] && mknod -m 666 urandom c 1 9
  [ ! -e tty ]     && mknod -m 666 tty c 5 0
  [ ! -e ptmx ]    && mknod -m 666 ptmx c 5 2
  
  # Link simbólico para fd (file descriptors)
  [ ! -e fd ] && ln -s /proc/self/fd fd
  [ ! -e stdin ] && ln -s fd/0 stdin
  [ ! -e stdout ] && ln -s fd/1 stdout
  [ ! -e stderr ] && ln -s fd/2 stderr

  popd >/dev/null
}
