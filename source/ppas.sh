#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Assembling rawimage
/usr/bin/as -o /home/pi/git/piext/source/lib/aarch64-linux/rawimage.o -march=armv8-a  /home/pi/git/piext/source/lib/aarch64-linux/rawimage.s
if [ $? != 0 ]; then DoExitAsm rawimage; fi
rm /home/pi/git/piext/source/lib/aarch64-linux/rawimage.s
echo Assembling piext
/usr/bin/as -o /home/pi/git/piext/source/lib/aarch64-linux/piext.o -march=armv8-a  /home/pi/git/piext/source/lib/aarch64-linux/piext.s
if [ $? != 0 ]; then DoExitAsm piext; fi
rm /home/pi/git/piext/source/lib/aarch64-linux/piext.s
echo Linking /home/pi/git/piext/source/piext
OFS=$IFS
IFS="
"
/usr/bin/ld.bfd  -L/usr/lib64 -L/usr/lib --dynamic-linker=/lib/ld-linux-aarch64.so.1       -L. -o /home/pi/git/piext/source/piext -T /home/pi/git/piext/source/link10653.res -e _start
if [ $? != 0 ]; then DoExitLink /home/pi/git/piext/source/piext; fi
IFS=$OFS
