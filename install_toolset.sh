#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# This file is part of the build pipeline for Inkscape on macOS.
#
# ### install_toolset.sh ###
# Install a pre-compiled version of the JHBuild toolset and required
# dependencies for Inkscape.

### load settings and functions ################################################

SELF_DIR=$(F=$0; while [ ! -z $(readlink $F) ] && F=$(readlink $F); \
  cd $(dirname $F); F=$(basename $F); [ -L $F ]; do :; done; echo $(pwd -P))
for script in $SELF_DIR/0??-*.sh; do source $script; done

set -e

### install toolset ############################################################

function install
{
  local toolset_dmg=$REPO_DIR/$(basename $URL_TOOLSET)

  if [ -f $toolset_dmg ]; then
    echo_i "no download required"
  else
    # File not present on disk, we need to download.
    echo_i "download required"
    download_url $URL_TOOLSET $REPO_DIR
  fi

  # mount build system read-only
  local device=$(create_dmg_device $toolset_dmg)
  [ ! -d $VER_DIR ] && mkdir -p $VER_DIR
  mount -o nobrowse,noowners,ro -t hfs $device $VER_DIR
  echo_i "toolset mounted as $device"

  # Sadly, there are some limitations involved with union-mounting:
  #   - Files are not visible to 'ls'.
  #   - You cannot write in a location without having written to its
  #     parent location. That's why we need to pre-create all directories
  #     below.
  #
  # Shadow-mounting a dmg is not a feasible alternative due to its
  # bad write-performance.

  # prepare a script for mass-creating directories
  find $VER_DIR -type d ! -path "$TMP_DIR/*" ! -path "$SRC_DIR/*" \
      -exec echo "mkdir {}" > $TOOLSET_ROOT_DIR/create_dirs.sh \;
  chmod 755 $TOOLSET_ROOT_DIR/create_dirs.sh

  # create writable (ramdisk-) overlay
  device=$(create_ram_device $OVERLAY_RAMDISK_SIZE build)
  mount -o nobrowse,rw,union -t hfs $device $VER_DIR
  echo_i "writable ramdisk overlay mounted as $device"

  # create all directories inside overlay
  $TOOLSET_ROOT_DIR/create_dirs.sh
  rm $TOOLSET_ROOT_DIR/create_dirs.sh
}

### main #######################################################################

$SELF_DIR/110-sysprep.sh
install
