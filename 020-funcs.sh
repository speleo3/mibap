# 020-funcs.sh
#
# This file contains all the global functions and is meant to be sourced by 
# other files.

[ -z $FUNCS_INCLUDED ] && FUNCS_INCLUDED=true || return   # include guard

source 010-vars.sh

### get repository version string ##############################################

function get_repo_version
{
  echo $(git -C $INK_SRC_DIR describe --tags --dirty)
}

### get compression flag by filename extension #################################

function get_comp_flag
{
  local file=$1

  local extension=${file##*.}

  case extension in
    gz) echo "z"  ;;
    bz2) echo "j" ;;
    xz) echo "J"  ;;
    *) echo "ERROR unknown extension $extension"
  esac
}

### download and extract source tarball ########################################

function get_source
{
  local url=$1

  cd $INK_SRC_DIR

  # This downloads a file and pipes it directly into tar (file is not saved
  # to disk), determines the decompression flag by its suffix and returns
  # the directory the files have been extracted to.
  local source_dir=$(curl -sL $url | 
                     tar xv$get_comp_flag($url) 2>&1 |
                     head -1 | 
                     awk '{ print $2 }')

  cd $source_dir
}

### make, make install in jhbuild environment ##################################

function make_makeinstall
{
  jhbuild run make
  jhbuild run make install
}

### configure, make, make install in jhbuild environment #######################

function configure_make_makeinstall
{
  local flags="$*"
  jhbuild ./configure --prefix=$OPT_DIR $flags
  make_makeinstall
}
