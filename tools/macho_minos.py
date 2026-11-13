#!/usr/bin/env python3
"""Print the minimum iOS version of every slice in a Mach-O file.

Used by CI to check the universal package without relying on toolchain
utilities. Output, one line per slice:  "<arch>: version <x.y>"

Reads LC_VERSION_MIN_IPHONEOS (0x25) or LC_BUILD_VERSION (0x32).
Standard library only.
"""

import struct
import sys

FAT_MAGIC = 0xCAFEBABE
MH_MAGIC = 0xFEEDFACE
MH_MAGIC_64 = 0xFEEDFACF
LC_VERSION_MIN_IPHONEOS = 0x25
LC_BUILD_VERSION = 0x32

CPU_TYPE_ARM = 12
CPU_TYPE_ARM64 = 0x0100000C
ARM_SUBTYPES = {9: "armv7", 11: "armv7s", 12: "armv7k", 6: "armv6"}


def arch_name(cputype, cpusubtype):
    sub = cpusubtype & 0x00FFFFFF
    if cputype == CPU_TYPE_ARM64:
        return "arm64e" if sub == 2 else "arm64"
    if cputype == CPU_TYPE_ARM:
        return ARM_SUBTYPES.get(sub, "arm(%d)" % sub)
    return "cpu(%#x)" % cputype


def decode_version(v):
    major, minor, patch = v >> 16, (v >> 8) & 0xFF, v & 0xFF
    return "%d.%d" % (major, minor) + (".%d" % patch if patch else "")


def slice_minos(data, offset):
    magic = struct.unpack_from("<I", data, offset)[0]
    if magic == MH_MAGIC:
        header_size = 28
    elif magic == MH_MAGIC_64:
        header_size = 32
    else:
        raise ValueError("not a little-endian Mach-O slice at %#x" % offset)
    cputype, cpusubtype, _filetype, ncmds, _sizeofcmds = struct.unpack_from("<iiIII", data, offset + 4)
    pos = offset + header_size
    found = None
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", data, pos)
        if cmd == LC_VERSION_MIN_IPHONEOS:
            found = decode_version(struct.unpack_from("<I", data, pos + 8)[0])
        elif cmd == LC_BUILD_VERSION:
            found = decode_version(struct.unpack_from("<I", data, pos + 12)[0])
        pos += cmdsize
    return arch_name(cputype, cpusubtype), found


def main(path):
    with open(path, "rb") as f:
        data = f.read()
    magic = struct.unpack_from(">I", data, 0)[0]
    if magic == FAT_MAGIC:
        nfat = struct.unpack_from(">I", data, 4)[0]
        offsets = [struct.unpack_from(">iiIII", data, 8 + i * 20)[2] for i in range(nfat)]
    else:
        offsets = [0]
    for off in offsets:
        arch, minos = slice_minos(data, off)
        print("%s: version %s" % (arch, minos or "none"))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: macho_minos.py <file>")
    main(sys.argv[1])
