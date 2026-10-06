### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
properties() { '
kernel.string=Wicked Kernel for the Foxxd A67L Gen 2 - Wicked Labs
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
do.check_boot_version=0
device.name1=A67L_Gen2
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
block=boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1

. tools/ak3-core.sh

# KernelSU is built into this kernel; a KernelSU-patched init_boot (LKM mode) would load a second copy at boot
mkdir -p $AKHOME/ib
dd if=/dev/block/by-name/init_boot$(getprop ro.boot.slot_suffix) of=$AKHOME/ib/init_boot.img 2>/dev/null
(cd $AKHOME/ib && magiskboot unpack init_boot.img >/dev/null 2>&1)
if [ -f $AKHOME/ib/ramdisk.cpio ] && magiskboot cpio $AKHOME/ib/ramdisk.cpio "exists kernelsu.ko"; then
  abort "  -> init_boot is KernelSU-patched. Restore stock init_boot first, without rebooting (README, step 2)."
fi
rm -rf $AKHOME/ib

split_boot
if [ -f "$SPLITIMG/ramdisk.cpio" ]; then
  unpack_ramdisk
  write_boot
else
  flash_boot
fi

ui_print " " "Wicked Kernel installed. Reboot to finish."
ui_print "https://github.com/thewickedlabs/Wicked-Kernel" " "
