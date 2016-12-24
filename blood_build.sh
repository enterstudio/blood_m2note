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

kernelpath=$(pwd)
buildpath=$kernelpath/build
sourcespath=$buildpath/obj
outpath=$kernelpath/out
zipbuildpath=$outpath/zip
toolchainpath=/opt/toolchain/UBERTC/aarch64-linux-android-5.x/bin/aarch64-linux-android-
date=$(date +"%Y%m%d%H%M")
model=m2note
arch=arm64
defconfig=blood_m2note_defconfig
bloodver=.r2.0-L
akscripts=$kernelpath/anykernel_blood
zipname=BLOOD$bloodver-$model-$date.zip
cputhreads=$(grep -c ^processor /proc/cpuinfo)

step1_parameters(){
  begin=$(date +"%s")
  echo "======================================================================"
  echo " "
  echo " "
  echo " "
  echo " "
  echo "                          Kernel parameters:                          "
  echo " "
  echo " ZIP name: $zipname "
  echo " Model: $model "
  echo " Defconfig: $defconfig "
  echo " Blood kernel version: $bloodver "
  echo " Build date: $date "
  echo " Host CPU threads: $cputhreads "
  echo " "
  echo " "
  echo " "
  echo " Kernel sources path: $kernelpath "
  echo " Toolchain path: $toolchainpath "
  echo " "
  echo " "
  echo " "
  echo " "
  echo "======================================================================"
}

step2_clean(){
  echo "Cleaning up directory..."

  if [ -d $buildpath ]
  then
      rm -r $buildpath
  fi

  if [ -d $outpath ]
  then
      rm -r $outpath
  fi
}

step3_setup(){
  echo "Setting variables..."
  export ARCH=$arch
  export SUBARCH=$arch
  export CROSS_COMPILE=$toolchainpath
  export CONFIG=$defconfig
  export KERNEL=$kernelpath
  export BUILD=$buildpath
  export SOURCES=$sourcespath
  export OUT=$outpath
  export ZIPBUILD=$zipbuildpath
  STRIP=${CROSS_COMPILE}strip
}

step4_compile(){
  echo "Building kernel..."
  mkdir -p $SOURCES
  mkdir -p $ZIPBUILD
  make O=$SOURCES $CONFIG
  make -j$cputhreads O=$SOURCES | tee $OUT/build-$model-$date.log

  if [ -f $SOURCES/arch/arm64/boot/Image.gz-dtb ]
  then
      cp -f $SOURCES/arch/arm64/boot/Image.gz-dtb $OUT/zImage
  fi

  echo "Kernel succesfully built!"
}

step5_generateprop(){
  echo "Generating prop file..."
  echo "# begin blood properties
ro.blood.model=$model
ro.blood.version=$bloodver
ro.blood.build_date=$date
ro.blood.build_user=$(whoami)
ro.blood.build_host=$(uname -n)
# end blood properties" > $ZIPBUILD/blood.prop
}

step6_createzip(){
  echo "Creating ZIP..."
  cp -r $akscripts/* $ZIPBUILD/
  cp -f $OUT/zImage $ZIPBUILD/zImage
  cd $ZIPBUILD
  zip -q -r -D -X $zipname ./*
}

step7_cleanafter(){
  echo "Cleaning after building..."
  mv $zipname $OUT/$zipname

  if [ -d $SOURCES ]
  then
      rm -r $SOURCES
  fi

  cd $OUT

  if [ -d $ZIPBUILD ]
  then
      rm -r $ZIPBUILD
  fi

  if [ -f zImage ]
  then
      rm -r zImage
  fi

  cd $KERNEL
  end=$(date +"%s")
  echo "Total time elapsed: $(echo $(($end-$begin)) | awk '{print int($1/60)"minutes "int($1%60)"seconds "}')"
}

step1_parameters;
step2_clean;
step3_setup;
step4_compile;
step5_generateprop;
step6_createzip;
step7_cleanafter;
