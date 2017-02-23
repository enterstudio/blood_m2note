#!/bin/bash
#
# BLOOD build script
#
# Copyright (C) 2016 @AlexLartsev19
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

function step1_setup(){
  echo "Setting building environment..."
  begin=$(date +"%s")
  # Dirs
  export KERNELDIR=$(pwd)
  export BUILDDIR=$KERNELDIR/build
  export OUTDIR=$KERNELDIR/out
  export SOURCESDIR=$BUILDDIR/obj
  export ZIPDIR=$BUILDDIR/zip
  # Kernel
  export ARCH=arm64
  export SUBARCH=arm64
  export CONFIG=blood_m2note_defconfig
  export VERSION=.r4.1-N
  export CROSS_COMPILE=/opt/toolchain/UBERTC/aarch64-linux-android-5.x/bin/aarch64-linux-android-
  STRIP=${CROSS_COMPILE}strip
  # Zip
  export MODEL=m2note
  export DATE=$(date +"%Y%m%d%H%M")
  export ZIP=BLOOD$VERSION-$MODEL-$DATE.zip
  # Host
  export KBUILD_BUILD_USER=$(whoami)
  export KBUILD_BUILD_HOST=$(uname -n)
  export THREADS=$(grep -c ^processor /proc/cpuinfo)
}

function step2_preparation(){
  echo " "
  echo " "
  echo " "
  echo " "
  echo "======================================================================"
  echo " "
  echo " "
  echo " "
  echo " "
  echo "                          Kernel parameters:                          "
  echo " "
  echo " Architecture: $ARCH "
  echo " Defconfig: $CONFIG "
  echo " Version: $VERSION "
  echo " Toolchain: $CROSS_COMPILE "
  echo " Zip: $OUTDIR/$ZIP "
  echo " Username: $KBUILD_BUILD_USER "
  echo " Hostname: $KBUILD_BUILD_HOST "
  echo " Host threads: $THREADS "
  echo " "
  echo " "
  echo " "
  echo " "
  echo "======================================================================"
  echo " "
  echo " "
  echo " "
  echo " "
  echo "Preparations for building"

  if [ -d $BUILDDIR ]
  then
      rm -rf $BUILDDIR
  fi

  if [ -d $OUTDIR ]
  then
      rm -rf $OUTDIR
  fi

  mkdir -p $BUILDDIR
  mkdir -p $OUTDIR
  mkdir -p $SOURCESDIR
  mkdir -p $ZIPDIR
}

function step3_building(){
  echo " "
  echo "Building kernel..."
  make O=$SOURCESDIR $CONFIG
  make -j$THREADS O=$SOURCESDIR

  if [ ! -f $SOURCESDIR/arch/$ARCH/boot/Image.gz-dtb ]
  then
      echo " "
      echo "Building kernel failed!"
  else
      mv $SOURCESDIR/arch/$ARCH/boot/Image.gz-dtb $ZIPDIR/zImage
      echo " "
      echo "Kernel succesfully built!"
      step4_zipit
  fi
}

function step4_zipit(){
  echo " "
  echo "Creating ZIP..."
  echo "# begin blood properties
ro.blood.model=$MODEL
ro.blood.version=$VERSION
ro.blood.build_date=$DATE
ro.blood.build_user=$KBUILD_BUILD_USER
ro.blood.build_host=$KBUILD_BUILD_HOST
# end blood properties" > $ZIPDIR/blood.prop
  cp -r $KERNELDIR/anykernel_blood/* $ZIPDIR/
  cp -r $(find -name '*.ko') $ZIPDIR/modules/
  cd $ZIPDIR
  find . -name placeholder -delete
  zip -q -r -D -X $ZIP ./*
  mv $ZIPDIR/$ZIP $OUTDIR/$ZIP
  end=$(date +"%s")
  echo " "
  echo "Total time elapsed: $(echo $(($end-$begin)) | awk '{print int($1/60)"minutes "int($1%60)"seconds "}')"
  echo "ZIP location: $OUTDIR/$ZIP"
  echo "ZIP size: $(du -h $OUTDIR/$ZIP | awk '{print $1}')"
  cd $KERNELDIR
}

step1_setup
step2_preparation
step3_building
