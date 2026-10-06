#!/usr/bin/env python3
"""Check every vendor module's imports against a built kernel's exports and CRCs.
usage: kmi_check.py vmlinux.symvers MODDIR..."""
import sys, struct, glob, os
from elftools.elf.elffile import ELFFile

exports = {}
for line in open(sys.argv[1]):
    crc, name = line.split('\t')[:2]
    exports[name] = int(crc, 16)

mods = {}
for d in sys.argv[2:]:
    for p in sorted(glob.glob(os.path.join(d, '**/*.ko'), recursive=True)):
        mods.setdefault(os.path.basename(p), p)

provided, imports = set(), {}
for name, p in mods.items():
    with open(p, 'rb') as f:
        e = ELFFile(f)
        crcs = {}
        v = e.get_section_by_name('__versions')
        if v:
            data = v.data()
            for i in range(0, len(data), 64):
                crc, = struct.unpack_from('<Q', data, i)
                crcs[data[i + 8:i + 64].split(b'\0')[0].decode()] = crc & 0xffffffff
        und = set()
        for s in e.get_section_by_name('.symtab').iter_symbols():
            if s['st_shndx'] == 'SHN_UNDEF' and s.name:
                und.add(s.name)
            elif s.name.startswith('__ksymtab_'):
                provided.add(s.name[10:])
        imports[name] = (und, crcs)

missing, bad = {}, {}
for name, (und, crcs) in imports.items():
    for s in und - provided:
        if s not in exports:
            missing.setdefault(s, []).append(name)
        elif s in crcs and crcs[s] != exports[s]:
            bad.setdefault(s, []).append(name)

print(f'modules {len(mods)}, kernel exports {len(exports)}')
print(f'missing symbols {len(missing)}, CRC mismatches {len(bad)}')
for title, d in (('MISSING', missing), ('CRC', bad)):
    for s, m in sorted(d.items()):
        print(f'  {title} {s}: {", ".join(sorted(m)[:5])}{" ..." if len(m) > 5 else ""}')
sys.exit(1 if missing or bad else 0)
