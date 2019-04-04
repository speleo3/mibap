#!/usr/bin/env bash
# 210-inkscape.sh
# https://github.com/dehesselle/mibap
#
# Finally, build and package Inkscape :-).

SELF_DIR=$(cd $(dirname "$0"); pwd -P)
for script in $SELF_DIR/0??-*.sh; do source $script; done

### build Inkscape #############################################################

if [ -z CI ]; then   # running standalone
  cd $SRC_DIR
  git clone --depth 1 https://gitlab.com/inkscape/inkscape
  #git clone https://gitlab.com/inkscape/inkscape   # this is a >1.5 GiB download
  mkdir inkscape_build
  cd inkscape_build
  cmake -DCMAKE_PREFIX_PATH=$OPT_DIR -DCMAKE_INSTALL_PREFIX=$OPT_DIR -DWITH_OPENMP=OFF ../inkscape
else   # running as CI job
  if [ -d $WRK_DIR/inkscape_build ]; then   # cleanup previous run
    rm -rf $WRK_DIR/inkscape_build
  fi
  cd $WRK_DIR
  mkdir $WRK_DIR/inkscape_build
  cd inkscape_build
  cmake -DCMAKE_PREFIX_PATH=$OPT_DIR -DCMAKE_INSTALL_PREFIX=$OPT_DIR -DWITH_OPENMP=OFF $SELF_DIR/../..
fi

make
make install

# patch library locations before packaging
install_name_tool -change @rpath/libpoppler.85.dylib $LIB_DIR/libpoppler.85.dylib $BIN_DIR/inkscape
install_name_tool -change @rpath/libpoppler-glib.8.dylib $LIB_DIR/libpoppler-glib.8.dylib $BIN_DIR/inkscape

### package Inkscape ###########################################################

cd $SELF_DIR
jhbuild run gtk-mac-bundler inkscape.bundle

# patch library locations
install_name_tool -change @rpath/libinkscape_base.dylib @executable_path/../Resources/lib/inkscape/libinkscape_base.dylib $APP_EXE_DIR/Inkscape-bin
install_name_tool -change @rpath/libpoppler.85.dylib @executable_path/../Resources/lib/libpoppler.85.dylib $APP_LIB_DIR/libpoppler-glib.8.dylib
install_name_tool -change @rpath/libpoppler.85.dylib @executable_path/../Resources/lib/libpoppler.85.dylib $APP_LIB_DIR/inkscape/libinkscape_base.dylib
install_name_tool -change @rpath/libpoppler-glib.8.dylib @executable_path/../Resources/lib/libpoppler-glib.8.dylib $APP_LIB_DIR/inkscape/libinkscape_base.dylib

# add INKSCAPE_DATADIR to launch script
# TODO instead of deleting and re-inserting, insert with sed before pattern
sed -i '' -e '$d' $APP_EXE_DIR/Inkscape
sed -i '' -e '$d' $APP_EXE_DIR/Inkscape
echo 'export INKSCAPE_DATADIR=$bundle_data' >> $APP_EXE_DIR/Inkscape
echo '$EXEC "$bundle_contents/MacOS/$name-bin" "$@" $EXTRA_ARGS' >> $APP_EXE_DIR/Inkscape

# add icon
cp $SELF_DIR/inkscape.icns $APP_RES_DIR

if [ -z CI ]; then   # running standalone
  # update version information
  /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString '1.0alpha-g$(get_repo_version $SRC_DIR/inkscape)'" $APP_PLIST
  /usr/libexec/PlistBuddy -c "Set CFBundleVersion '1.0alpha-g$(get_repo_version $SRC_DIR/inkscape)'" $APP_PLIST
else   # running as CI job
  # update version information
  /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString '1.0alpha-g$(get_repo_version $SELF_DIR)'" $APP_PLIST
  /usr/libexec/PlistBuddy -c "Set CFBundleVersion '1.0alpha-g$(get_repo_version $SELF_DIR)'" $APP_PLIST
fi

### create disk image for distribution #########################################

# TODO