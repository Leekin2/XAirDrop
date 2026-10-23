"""Make libxos treat an unsupported wonder SET_FEATURES (aggregation config) as success.

The OPAirDrop wonder.ko has no SET_FEATURES vendor command, so libxos's aggregation
config returns -1 and the whole XOS session aborts. At both call sites:
    mov w19, w0          ->  mov w19, wzr      (result = 0)
    tbz w0, #31, ok      ->  b ok              (always take the success path)
Usage: patch_libxos.py <in> <out>
"""
import struct
import sys

SITES = [  # (mov offset, tbz offset, success label)
    (0x177f0, 0x177f4, 0x178c4),
    (0x17a18, 0x17a1c, 0x17aec),
]
MOV_W19_W0 = 0x2A0003F3
MOV_W19_WZR = 0x2A1F03F3

src, dst = sys.argv[1], sys.argv[2]
data = bytearray(open(src, 'rb').read())
for mov, tbz, ok in SITES:
    word = struct.unpack_from('<I', data, mov)[0]
    assert word == MOV_W19_W0, f'{mov:#x}: unexpected {word:#010x}'
    tbz_word = struct.unpack_from('<I', data, tbz)[0]
    assert tbz_word & 0x7F000000 == 0x36000000, f'{tbz:#x}: not tbz ({tbz_word:#010x})'
    struct.pack_into('<I', data, mov, MOV_W19_WZR)
    struct.pack_into('<I', data, tbz, 0x14000000 | ((ok - tbz) // 4 & 0x3FFFFFF))
    print(f'patched {mov:#x} and {tbz:#x} -> b {ok:#x}')
open(dst, 'wb').write(data)
