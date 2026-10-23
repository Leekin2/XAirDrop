"""Rewrite symbol CRCs in a module's __versions table.

Usage: patchcrc.py <in.ko> <out.ko> <symbol>=<hexcrc> [...]
Each named symbol must already be imported by the module; nothing else changes.
"""
import struct
import sys

from elftools.elf.elffile import ELFFile


def main():
    src, dst, *pairs = sys.argv[1:]
    wanted = {name: int(crc, 16) for name, crc in (p.split('=') for p in pairs)}
    data = bytearray(open(src, 'rb').read())
    with open(src, 'rb') as f:
        sec = ELFFile(f).get_section_by_name('__versions')
        base, size = sec['sh_offset'], sec['sh_size']
    done = set()
    for off in range(base, base + size, 64):
        name = bytes(data[off + 8:off + 64]).split(b'\0', 1)[0].decode()
        if name in wanted:
            old = struct.unpack_from('<Q', data, off)[0]
            struct.pack_into('<Q', data, off, wanted[name])
            print(f'{name}: {old & 0xffffffff:08x} -> {wanted[name]:08x}')
            done.add(name)
    missing = set(wanted) - done
    if missing:
        sys.exit(f'not imported: {", ".join(sorted(missing))}')
    open(dst, 'wb').write(data)


if __name__ == '__main__':
    main()
