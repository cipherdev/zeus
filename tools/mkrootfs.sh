#!/bin/sh
#
# How to create Ramdisk Image.
# Author: HuyLe (anhhuy@live.com)
#
USAGE="\nUsage:\n\
\t- Making a ramdisk file from a directory:\n\t\t`basename $0` -c <rootfs dir, e.g: tmp (default)> -o <new ramdisk file, e.g: uRamdisk (default)> -n < describe for new ramdisk file>\n\
\t- Extracting a ramdisk file to a directory:\n\t\t`basename $0` -x <ramdisk file> -o <new rootfs dir, e.g: tmp (default)>\n"

while getopts ":c:x:o:n:" opt; do
        case $opt in
                c ) rootfs_dir="$OPTARG";;
                x ) ramdisk_file="$OPTARG";;
                o ) tmp="$OPTARG" ;;
                n ) DEST="$OPTARG" ;;
                \? ) echo -e "${USAGE}"
                    exit 1;;
        esac
done
shift $(($OPTIND - 1))

[ -z "${tmp}" ] && tmp="tmp"
# Compressing/making a ramdisk file
if [ ! -z ${rootfs_dir} ]; then
        echo -e "'${rootfs_dir}' directory (rootfs) will be compressed by 'lzma'.\n\twaiting...being compressed..\n"
        (sudo sh -c "cd ${rootfs_dir}; find . | cpio -H newc -o | lzma -9 > ../${tmp}.cpio.gz")
        #(sudo sh -c "cd ${rootfs_dir}; find . | cpio -H newc -o | xz -9 -C crc32 -c > ../${uram_new_file}.cpio.gz")
        [ -f "${tmp}" ] && sudo rm -rf "${tmp}"
        sudo mkimage -A arm -O linux -T ramdisk -C lzma -n "${DEST}" -d ${tmp}.cpio.gz ${tmp}
        sudo rm -rf ${tmp}.cpio.gz
        exit 0
fi

# Uncompress the ramdisk file
if [ ! -z ${ramdisk_file} ]; then
        [ -d "${tmp}" ] && sudo rm -rf "${tmp}"
        sudo mkdir -p "${tmp}"
        compress=`file ${ramdisk_file} | grep -Eo "lzma|cpio|gzip"`
        sudo dd if=${ramdisk_file} of=${tmp}/${ramdisk_file}.tmp bs=64 skip=1
        cd  "${tmp}"
        echo "'${ramdisk_file}' file was compressed by '${compress}'"
        case "${compress}" in
                "cpio") sudo sh -c "cpio -id < ${ramdisk_file}.tmp";;

                "gzip") sudo sh -c "zcat ${ramdisk_file}.tmp | cpio -id";;
                "lzma")
                        sudo mv ${ramdisk_file}.tmp ${ramdisk_file}.tmp.xz
                        sudo xz -d ${ramdisk_file}.tmp.xz
                        sudo sh -c "cat ${ramdisk_file}.tmp | cpio -id";;
                *) echo "Unknown file type";;
        esac
        sudo rm -rf ${ramdisk_file}.tmp
        exit 0
fi
exit 1
