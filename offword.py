#!/usr/bin/env python
import sys
s = sys.stdin.read()
L = []
for w in s.split():
    if w not in L:
        L.append(w)

print " ".join(L)        

