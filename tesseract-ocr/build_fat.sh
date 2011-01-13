#!/bin/sh
# build_fat.sh
#
# Created by Robert Carlsen on 15.07.2009. Updated 24.9.2010
# build an arm / i386 lib of standard linux project
#
# initially configured for tesseract-ocr v2.0.4
# updated for tesseract prerelease v3
 
outdir=outdir
mkdir -p $outdir/arm $outdir/i386
 
libdirs=( api ccutil ccmain ccstruct classify cutil dict image textord training viewer wordrec )
libs=( api ccutil main ccstruct classify cutil dict image textord training viewer wordrec )
count=${#libdirs[@]}
 
make distclean
unset CPPFLAGS CFLAGS LDFLAGS CPP CXX CC CXXFLAGS DEVROOT SDKROOT LD
 
export DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer
export SDKROOT=$DEVROOT/SDKs/iPhoneOS4.2.sdk
export CFLAGS="-arch armv6 -pipe -no-cpp-precomp -isysroot$SDKROOT -miphoneos-version-min=3.0 -I$SDKROOT/usr/include/"
export CPPFLAGS="$CFLAGS"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-L$SDKROOT/usr/lib/"
export LD="$DEVROOT/usr/bin/ld"
export CPP="$DEVROOT/usr/bin/cpp-4.2"
export CXX="$DEVROOT/usr/bin/g++-4.2"
export CC="$DEVROOT/usr/bin/gcc-4.2"
./configure --host=arm-apple-darwin
make -j3
 
index=0
while [ "$index" -lt "$count" ]
do
    cp ${libdirs[index]}/.libs/libtesseract_${libs[index]}.a $outdir/arm/libtesseract_${libs[index]}_armv6.a
    ((index++))
done
 
make distclean
unset CPPFLAGS CFLAGS LDFLAGS CPP CXX CC CXXFLAGS DEVROOT SDKROOT LD
 
export DEVROOT=/Developer/Platforms/iPhoneSimulator.platform/Developer
export SDKROOT=$DEVROOT/SDKs/iPhoneSimulator4.2.sdk
export CFLAGS="-arch i386 -pipe -no-cpp-precomp -isysroot$SDKROOT -miphoneos-version-min=3.0 -I$SDKROOT/usr/include/"
export CPPFLAGS="$CFLAGS"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-L$SDKROOT/usr/lib/"
export LD="$DEVROOT/usr/bin/ld"
export CPP="$DEVROOT/usr/bin/cpp-4.2"
export CXX="$DEVROOT/usr/bin/g++-4.2"
export CC="$DEVROOT/usr/bin/gcc-4.2"
./configure
make -j3
 
index=0
while [ "$index" -lt "$count" ]
do
    cp ${libdirs[index]}/.libs/libtesseract_${libs[index]}.a $outdir/i386/libtesseract_${libs[index]}_i386.a
    ((index++))
done
 
# are the fat libs making the bundle too big?
index=0
while [ "$index" -lt "$count" ]
do
    /usr/bin/lipo -arch armv6 $outdir/arm/libtesseract_${libs[index]}_armv6.a -arch i386 $outdir/i386/libtesseract_${libs[index]}_i386.a -create -output $outdir/libtesseract_${libs[index]}.a
    ((index++))
done
 
unset CPPFLAGS CFLAGS LDFLAGS CPP CXX CC CXXFLAGS DEVROOT SDKROOT