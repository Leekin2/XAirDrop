"""Compare the symbol CRCs a kernel module imports with what another module set provides.

Usage: modcrc.py <module.ko> <reference_dir>
  Reads __versions (imported symbol -> CRC) of <module.ko>, then collects every CRC that the
  stock modules in <reference_dir> import or export, and reports matches, mismatches and
  symbols the reference set never mentions.
"""
import os
import struct
import sys

from elftools.elf.elffile import ELFFile


def imports(path):
    """__versions: 64-bit entries of (u64 crc, char name[56])."""
    with open(path, 'rb') as f:
        elf = ELFFile(f)
        sec = elf.get_section_by_name('__versions')
        if sec is None:
            return {}
        data = sec.data()
    out = {}
    for i in range(0, len(data), 64):
        crc = struct.unpack_from('<Q', data, i)[0] & 0xffffffff
        name = data[i + 8:i + 64].split(b'\0', 1)[0].decode()
        out[name] = crc
    return out


def exports(path):
    """__kcrctab* (u32 CRCs) paired with __ksymtab_strings order via the symbol table."""
    out = {}
    with open(path, 'rb') as f:
        elf = ELFFile(f)
        symtab = elf.get_section_by_name('.symtab')
        if symtab is None:
            return out
        for sym in symtab.iter_symbols():
            if sym.name.startswith('__crc_'):
                # In modules __crc_ symbols are absolute values (the CRC itself) or point into __kcrctab.
                sec_idx = sym['st_shndx']
                if sec_idx == 'SHN_ABS':
                    out[sym.name[6:]] = sym['st_value'] & 0xffffffff
                else:
                    sec = elf.get_section(sec_idx)
                    off = sym['st_value'] - sec['sh_addr']
                    out[sym.name[6:]] = struct.unpack_from('<I', sec.data(), off)[0]
    return out


def main():
    module, ref_dir = sys.argv[1], sys.argv[2]
    wanted = imports(module)
    known = {}
    for name in os.listdir(ref_dir):
        if not name.endswith('.ko'):
            continue
        path = os.path.join(ref_dir, name)
        for sym, crc in imports(path).items():
            known.setdefault(sym, set()).add(crc)
        for sym, crc in exports(path).items():
            known.setdefault(sym, set()).add(crc)
    ok, bad, missing = [], [], []
    for sym, crc in sorted(wanted.items()):
        if sym not in known:
            missing.append(sym)
        elif crc in known[sym]:
            ok.append(sym)
        else:
            bad.append((sym, crc, sorted(known[sym])))
    print(f'{os.path.basename(module)}: {len(wanted)} imports, {len(ok)} match, '
          f'{len(bad)} CRC mismatch, {len(missing)} not seen in reference set')
    for sym, crc, have in bad:
        print(f'  MISMATCH {sym}: wants {crc:08x}, reference has {" ".join(f"{c:08x}" for c in have)}')
    for sym in missing:
        print(f'  UNSEEN   {sym}')


if __name__ == '__main__':
    main()
