"""Move a module's init/exit pointers in struct module to where a reference module has them.

Our ACK-built module put `exit` at 0x5a8; the Xiaomi kernel's struct module (as in every
stock module) has it at 0x5b8, so the kernel read a garbage pointer in mod_sysfs_setup.
struct module in a .ko only carries the name and these two relocations (the rest is zero),
so rewriting the relocation offsets gives the kernel's exact layout.
Usage: fixmodlayout.py <module.ko> <reference.ko> <out.ko>
"""
import struct
import sys

from elftools.elf.elffile import ELFFile

src, ref, dst = sys.argv[1:4]


def relocs(path):
    e = ELFFile(open(path, 'rb'))
    rs = e.get_section_by_name('.rela.gnu.linkonce.this_module')
    st = e.get_section_by_name('.symtab')
    out = {}
    for n, r in enumerate(rs.iter_relocations()):
        out[st.get_symbol(r['r_info_sym']).name] = (n, r['r_offset'])
    return rs['sh_offset'], rs['sh_entsize'], out


_, _, want = relocs(ref)
off, entsize, have = relocs(src)
data = bytearray(open(src, 'rb').read())
for name, (n, cur) in have.items():
    target = want[name][1]
    if cur != target:
        struct.pack_into('<Q', data, off + n * entsize, target)
        print(f'{name}: {cur:#x} -> {target:#x}')
    else:
        print(f'{name}: {cur:#x} ok')
open(dst, 'wb').write(data)
