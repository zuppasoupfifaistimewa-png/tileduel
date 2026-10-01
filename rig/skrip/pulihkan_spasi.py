import difflib, sys
basis, target = sys.argv[1], sys.argv[2]
a = open(basis, encoding='utf-8').read().split('\n')
b = open(target, encoding='utf-8').read().split('\n')
sm = difflib.SequenceMatcher(None, [x.rstrip() for x in a], [x.rstrip() for x in b], autojunk=False)
out = []; restored = 0
for tag, i1, i2, j1, j2 in sm.get_opcodes():
    if tag == 'equal':
        for k in range(i2 - i1):
            if a[i1 + k] != b[j1 + k]: restored += 1
            out.append(a[i1 + k])
    else:
        out.extend(b[j1:j2])
open(target, 'w', encoding='utf-8').write('\n'.join(out))
print(target, "baris dipulihkan:", restored)
