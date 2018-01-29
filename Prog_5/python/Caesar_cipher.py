import numpy as np
import string

print('######################### --- brute force --- #########################')
file = open('Logos.txt.crp', 'r')
out = open('ascii_table.txt','w')
fl = file.read()
printable_chars = ''.join(chr(c) for c in range(33, 127))
out.write(printable_chars)
#letters = len(printable_chars)
'''
for k in range(letters):
    decrypt_BF_text = ''
    cryptLetters = np.roll(printable_chars, k)

    for i in fl:
        fl(i) == cryptLetters
        ind = fl(i)
        l = letters(ind)
        if not l:
            decrypt_BF_text(i) == file(i)
        else:
            i = i + (len(l)-1)
            #decrypt_BF_text(i) ==
'''