#!/bin/sh

if [ -z $1 ]; then
	echo "Kernel will be labelled ($KBUILD_BUILD_VERSION)"
else
	echo "Setting kernel name to ($1)"
	export KBUILD_BUILD_VERSION=$1
fi

echo "Compiling the kernel"
make -j2

echo "Tarballing the kernel"
cp arch/arm/boot/zImage ./
tar cf $KBUILD_BUILD_VERSION-zImage.tar zImage
rm zImage

echo "Done"
